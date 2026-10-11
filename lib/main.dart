import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';

void main() => runApp(MaterialApp(debugShowCheckedModeBanner: false, home: LoginGate()));

class LoginGate extends StatefulWidget { @override State<LoginGate> createState()=> _LoginGateState(); }
class _LoginGateState extends State<LoginGate> {
  @override Widget build(BuildContext context){
    return LoginPage(onSuccess: (){ Navigator.pushReplacement(context, MaterialPageRoute(builder: (_)=> DainikKharchApp())); });
  }
}

class LoginPage extends StatefulWidget {
  final VoidCallback onSuccess;
  LoginPage({required this.onSuccess});
  @override State<LoginPage> createState()=> _LoginPageState();
}
class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  final LocalAuthentication auth = LocalAuthentication();
  List<int> enteredPattern = [];
  List<int> savedPattern = [];
  bool isSettingPattern = false;
  String statusText = "Draw pattern or touch ORIGINAL sensor";
  Offset? fingerPos;
  late AnimationController pulseCtrl;

  @override void initState(){ super.initState(); pulseCtrl = AnimationController(vsync: this, duration: Duration(milliseconds: 1200))..repeat(reverse: true); loadPattern(); }
  @override void dispose(){ pulseCtrl.dispose(); super.dispose(); }

  void loadPattern() async {
    final p = await SharedPreferences.getInstance();
    String? pat = p.getString('userPattern_v2');
    if(pat!=null && pat.isNotEmpty){
      savedPattern = pat.split(',').map((e)=> int.parse(e)).toList();
      setState(()=> statusText = "Pattern draw kara kinva khalchya sensor la touch kara");
    } else {
      setState(()=> isSettingPattern = true);
      setState(()=> statusText = "Set pattern - Join 4 dots");
    }
  }
  void savePattern(List<int> pat) async {
    final p = await SharedPreferences.getInstance();
    await p.setString('userPattern_v2', pat.join(','));
    HapticFeedback.heavyImpact();
    setState(()=> savedPattern=pat); isSettingPattern=false; statusText="Pattern saved! Now draw it"; enteredPattern=[];
  }

  // === 100% REAL FINGERPRINT - Fakt tumchach gheil - Dusryacha nahi! ===
  Future<void> tryFingerprint() async {
    try{
      bool canCheck = await auth.canCheckBiometrics;
      bool isSupported = await auth.isDeviceSupported();
      List<BiometricType> available = await auth.getAvailableBiometrics();
      if(!isSupported ||!canCheck){ setState(()=> statusText="Device doesn't support fingerprint"); return; }
      if(available.isEmpty){ setState(()=> statusText="Fingerprint not enrolled - Add in Settings"); return; }
      bool didAuth = await auth.authenticate(
        localizedReason: 'खर्च वही अनलॉक करण्यासाठी तुमचा खरा बोट ठेवा - Fakt tumchach chalanar!',
        options: AuthenticationOptions(
          biometricOnly: true, // Fakt khara fingerprint - PIN nahi!
          stickyAuth: true,
          useErrorDialogs: true
        )
      );
      if(didAuth){ HapticFeedback.heavyImpact(); widget.onSuccess(); }
    } catch(e){ setState(()=> statusText="Error: $e"); }
  }

  int? getDotIndex(Offset pos, Size size){
    double cellW = size.width/3; double cellH = size.height/3;
    for(int i=0;i<9;i++){ int r=i~/3; int c=i%3; Offset cen=Offset(c*cellW+cellW/2, r*cellH+cellH/2); if((pos-cen).distance<45) return i; }
    return null;
  }

  @override Widget build(BuildContext context){
    return Scaffold(
      backgroundColor: Color(0xFF070A11),
      body: SafeArea(
        child: Stack(children: [
          Positioned(top: -60, left: -50, child: Container(width: 180, height: 180, decoration: BoxDecoration(shape: BoxShape.circle, color: Color(0xFF00E676).withOpacity(0.10)))),
          SingleChildScrollView(
            child: Padding(padding: EdgeInsets.only(bottom: 180, top: 20), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Center(child: Container(padding: EdgeInsets.all(2), decoration: BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [Color(0xFF00E676), Color(0xFFD4FF5A)])), child: Container(padding: EdgeInsets.all(14), decoration: BoxDecoration(shape: BoxShape.circle, color: Color(0xFF12151E)), child: Icon(Icons.wallet, size: 32, color: Color(0xFF00E676))))),
              SizedBox(height: 12),
              Text("खर्चाची नोंद वही", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 22)),
              SizedBox(height: 6),
              Container(padding: EdgeInsets.symmetric(horizontal: 14, vertical: 6), decoration: BoxDecoration(color: Colors.white.withOpacity(0.06), borderRadius: BorderRadius.circular(20)), child: Text(statusText, style: TextStyle(color: Colors.white70, fontSize: 11))),
              SizedBox(height: 20),
              Center(child: Container(width: 300, height: 340, decoration: BoxDecoration(color: Color(0xFF12151E), borderRadius: BorderRadius.circular(28), border: Border.all(color: Colors.white.withOpacity(0.08))), child: Padding(padding: EdgeInsets.all(16), child: GestureDetector(
                onPanStart: (d){ setState(()=> enteredPattern=[]); },
                onPanUpdate: (d){ Size sz=Size(268, 308); int? idx=getDotIndex(d.localPosition, sz); if(idx!=null &&!enteredPattern.contains(idx)){ HapticFeedback.selectionClick(); setState(()=> enteredPattern.add(idx)); fingerPos=d.localPosition; } },
                onPanEnd: (d){ setState(()=> fingerPos=null); if(isSettingPattern){ if(enteredPattern.length<4){ setState(()=> statusText="At least 4 dots needed!"); enteredPattern=[]; } } else { if(enteredPattern.length>=4){ if(savedPattern.isEmpty || enteredPattern.join(',')==savedPattern.join(',')){ widget.onSuccess(); } else { HapticFeedback.vibrate(); setState(()=> statusText="Wrong pattern! Try again"); Future.delayed(Duration(milliseconds: 400), ()=> setState(()=> enteredPattern=[])); } } } },
                child: CustomPaint(
                  painter: ModernPatternPainter(enteredPattern: enteredPattern, fingerPos: fingerPos),
                  child: GridView.builder(physics: NeverScrollableScrollPhysics(), gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 14, mainAxisSpacing: 14, childAspectRatio: 1), itemCount: 9, itemBuilder: (c,i){ bool sel=enteredPattern.contains(i); return Container(decoration: BoxDecoration(color: sel?Color(0xFF00E676):Color(0xFF1E2330), shape: BoxShape.circle, border: Border.all(color: sel?Color(0xFF00E676):Colors.white12, width: sel?2.5:1)), child: Center(child: Container(width: sel?12:6, height: sel?12:6, decoration: BoxDecoration(color: sel?Colors.black:Colors.white24, shape: BoxShape.circle)))); }),
                ),
              )))),
              SizedBox(height: 12),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                TextButton(onPressed: ()=> setState(()=> enteredPattern=[]), child: Text("Clear", style: TextStyle(color: Colors.white30, fontSize: 12))),
                if(isSettingPattern && enteredPattern.length>=4) ElevatedButton(onPressed: ()=> savePattern(enteredPattern), style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF00E676), foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))), child: Text("Save Pattern", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
              ]),
            ])),
          ),
          // === CORRECTED LOCATION - EKDOM KHALI 25px ===
          Positioned(
            bottom: 25, // Ithech badal kela - 75 hota aata 25 kela!
            left: 0, right: 0,
            child: Column(children: [
              ScaleTransition(
                scale: Tween(begin: 1.0, end: 1.15).animate(CurvedAnimation(parent: pulseCtrl, curve: Curves.easeInOut)),
                child: GestureDetector(
                  onTap: tryFingerprint,
                  child: Stack(alignment: Alignment.center, children: [
                    Container(width: 88, height: 88, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white.withOpacity(0.35), width: 1.8))),
                    Container(width: 58, height: 58, decoration: BoxDecoration(shape: BoxShape.circle, color: Color(0xFF12151E), border: Border.all(color: Color(0xFF00E676), width: 2.2), boxShadow: [BoxShadow(color: Color(0xFF00E676).withOpacity(0.6), blurRadius: 22)]), child: Icon(Icons.fingerprint_rounded, color: Color(0xFF00E676), size: 28)),
                  ]),
                ),
              ),
              SizedBox(height: 10),
              GestureDetector(onTap: tryFingerprint, child: Container(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6), decoration: BoxDecoration(color: Color(0xFF1A1F2E), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white12)), child: Text("खरा Sensor ला Touch करा - Fakt tumchach", style: TextStyle(color: Colors.white70, fontSize: 10)))),
            ]),
          ),
        ]),
      ),
    );
  }
}

class ModernPatternPainter extends CustomPainter {
  final List<int> enteredPattern; final Offset? fingerPos;
  ModernPatternPainter({required this.enteredPattern, this.fingerPos});
  @override void paint(Canvas canvas, Size size){
    if(enteredPattern.isEmpty) return;
    Paint linePaint = Paint()..color=Color(0xFF00E676)..strokeWidth=5..style=PaintingStyle.stroke..strokeCap=StrokeCap.round;
    double cellW = size.width/3; double cellH = size.height/3;
    List<Offset> points = [];
    for(int idx in enteredPattern){ int row = idx ~/ 3; int col = idx % 3; points.add(Offset(col*cellW + cellW/2, row*cellH + cellH/2)); }
    for(int i=0;i<points.length-1;i++){ canvas.drawLine(points[i], points[i+1], linePaint); }
    if(fingerPos!=null && points.isNotEmpty){ canvas.drawLine(points.last, fingerPos!, linePaint); }
  }
  @override bool shouldRepaint(covariant CustomPainter oldDelegate)=>true;
}class Expense {
  String title, amount, cat; DateTime date;
  Expense({required this.title, required this.amount, required this.cat, required this.date});
  Map toJson() => {'t':title,'a':amount,'c':cat,'d':date.toIso8601String()};
  factory Expense.fromJson(Map j) => Expense(title:j['t'], amount:j['a'].toString(), cat:j['c'], date:DateTime.parse(j['d']));
}
class Udhaari {
  String name, amount, type; DateTime date;
  Udhaari({required this.name, required this.amount, required this.type, required this.date});
  Map toJson() => {'n':name,'a':amount,'t':type,'d':date.toIso8601String()};
  factory Udhaari.fromJson(Map j) => Udhaari(name:j['n'], amount:j['a'].toString(), type:j['t'], date:DateTime.parse(j['d']));
}
class DainikKharchApp extends StatefulWidget { @override State<DainikKharchApp> createState()=>_DState(); }
class _DState extends State<DainikKharchApp> {
  List<Expense> exps = []; List<Udhaari> udhars = [];
  DateTime selDate = DateTime.now(); int tab = 0;
  double monthlyBudget = 4000;
  List<Map<String, dynamic>> catBlocks = [
    {"title":"भाजीपाला","icon":"🥬","cat":"भाजीपाला","c1":0xFF00C853,"c2":0xFF69F0AE},
    {"title":"किराणा","icon":"🛒","cat":"किराणा","c1":0xFFD500F9,"c2":0xFFEA80FC},
    {"title":"पेट्रोल","icon":"⛽","cat":"प्रवास","c1":0xFF2962FF,"c2":0xFF82B1FF},
    {"title":"लाईट बिल","icon":"💡","cat":"बिल","c1":0xFFFF6D00,"c2":0xFFFFAB40},
    {"title":"रिचार्ज","icon":"📱","cat":"रिचार्ज","c1":0xFF00B8D4,"c2":0xFF84FFFF},
    {"title":"चहा नाश्ता","icon":"☕","cat":"खाद्य","c1":0xFFFF1744,"c2":0xFFFF8A80},
    {"title":"इतर","icon":"➕","cat":"इतर","c1":0xFF6C757D,"c2":0xFFADB5BD},
  ];
  @override void initState(){ super.initState(); load(); }
  Future<void> load() async { final p = await SharedPreferences.getInstance(); var s = p.getString('ex'); if(s!=null) exps = (jsonDecode(s) as List).map((e)=>Expense.fromJson(e)).toList(); var u = p.getString('ud'); if(u!=null) udhars = (jsonDecode(u) as List).map((e)=>Udhaari.fromJson(e)).toList(); var b = p.getDouble('budget'); if(b!=null) monthlyBudget=b; setState((){}); }
  Future<void> save() async { final p = await SharedPreferences.getInstance(); p.setString('ex', jsonEncode(exps.map((e)=>e.toJson()).toList())); p.setString('ud', jsonEncode(udhars.map((e)=>e.toJson()).toList())); p.setDouble('budget', monthlyBudget); }
  bool sameDay(DateTime a,b) => a.year==b.year && a.month==b.month && a.day==b.day;
  void addExp(String t,String a,String c){ setState(()=> exps.insert(0, Expense(title:t, amount:a, cat:c, date:selDate))); save(); }
  void editBudgetDialog(){
    TextEditingController bCtrl = TextEditingController(text: monthlyBudget.toInt().toString());
    showDialog(context: context, builder: (ctx)=> AlertDialog(backgroundColor: Color(0xFF1E2635), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), title: Text("बजेट टाका", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)), content: TextField(controller: bCtrl, keyboardType: TextInputType.number, autofocus: true, style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold), decoration: InputDecoration(prefixText: "₹ ", filled: true, fillColor: Colors.white10, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))), actions: [TextButton(onPressed: ()=>Navigator.pop(ctx), child: Text("रद्द")), ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF00E676)), onPressed: (){ if(bCtrl.text.isNotEmpty){ setState(()=> monthlyBudget = double.tryParse(bCtrl.text)??4000); save(); Navigator.pop(ctx); } }, child: Text("Save", style: TextStyle(color: Colors.black)))],));
  }
  void showListOptions(int index, Expense e){
    TextEditingController tCtrl = TextEditingController(text: e.title);
    TextEditingController aCtrl = TextEditingController(text: e.amount);
    showModalBottomSheet(context: context, backgroundColor: Color(0xFF12151E), shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))), builder: (ctx)=> Padding(padding: EdgeInsets.all(20), child: Column(mainAxisSize: MainAxisSize.min, children: [Text("एडिट / डिलीट", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)), SizedBox(height: 14), TextField(controller: tCtrl, style: TextStyle(color: Colors.white), decoration: InputDecoration(labelText: "नाव", filled: true, fillColor: Colors.white10, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))), SizedBox(height: 10), TextField(controller: aCtrl, keyboardType: TextInputType.number, style: TextStyle(color: Colors.white), decoration: InputDecoration(labelText: "रक्कम", filled: true, fillColor: Colors.white10, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))), SizedBox(height: 16), Row(children: [Expanded(child: ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent), icon: Icon(Icons.delete), label: Text("डिलीट"), onPressed: (){ setState(()=> exps.removeAt(index)); save(); Navigator.pop(ctx); })), SizedBox(width: 10), Expanded(child: ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF00E676)), icon: Icon(Icons.save), label: Text("अपडेट"), onPressed: (){ setState(()=> exps[index] = Expense(title: tCtrl.text, amount: aCtrl.text, cat: e.cat, date: e.date)); save(); Navigator.pop(ctx); })),]),])));
  }
  void openManualEntry(Map<String, dynamic> block){
    TextEditingController amtCtrl = TextEditingController();
    TextEditingController noteCtrl = TextEditingController(text: block['title']);
    showDialog(context: context, builder: (ctx)=> Dialog(backgroundColor: Colors.transparent, child: Container(padding: EdgeInsets.all(20), decoration: BoxDecoration(color: Color(0xFF1E2635), borderRadius: BorderRadius.circular(24)), child: Column(mainAxisSize: MainAxisSize.min, children: [Text("${block['title']} खर्च", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)), SizedBox(height: 14), TextField(controller: amtCtrl, keyboardType: TextInputType.number, autofocus: true, style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900), decoration: InputDecoration(prefixText: "₹ ", filled: true, fillColor: Colors.white10, border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none))), SizedBox(height: 10), TextField(controller: noteCtrl, style: TextStyle(color: Colors.white), decoration: InputDecoration(labelText: "तपशील", filled: true, fillColor: Colors.white10, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))), SizedBox(height: 14), ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Color(block['c1'])), onPressed: (){ if(amtCtrl.text.isNotEmpty){ addExp(noteCtrl.text.isEmpty? block['title'] : noteCtrl.text, amtCtrl.text, block['cat']); Navigator.pop(ctx); } }, child: Text("Add करा"))]))));
  }

  @override Widget build(BuildContext context){
    return Scaffold(
      backgroundColor: Color(0xFF070A11),
      body: tab==0? buildDash() : tab==1? buildLedger() : tab==2? buildUdhaari() : buildGraphPage(),
      bottomNavigationBar: Container(margin: EdgeInsets.all(14), padding: EdgeInsets.all(6), decoration: BoxDecoration(color: Color(0xFF12151E), borderRadius: BorderRadius.circular(28), border: Border.all(color: Colors.white10)), child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [nav(Icons.dashboard_rounded,0), nav(Icons.receipt_long_rounded,1), nav(Icons.handshake_rounded,2), nav(Icons.bar_chart_rounded,3)])),
    );
  }
  Widget nav(IconData ic,int idx){ bool s=tab==idx; return GestureDetector(onTap: ()=>setState(()=>tab=idx), child: AnimatedContainer(duration: Duration(milliseconds: 250), padding: EdgeInsets.symmetric(horizontal: 22, vertical: 12), decoration: BoxDecoration(color: s?Color(0xFF00E676):Colors.transparent, borderRadius: BorderRadius.circular(20)), child: Icon(ic, color: s?Colors.black:Colors.white38, size: 22))); }

  Widget buildDash(){
    double today=0; for(var e in exps){ if(sameDay(e.date, selDate)) today+= double.tryParse(e.amount)??0; }
    double perc = (today/monthlyBudget).clamp(0,1);
    double remaining = monthlyBudget - today;
    var todaysList = exps.where((e)=>sameDay(e.date, selDate)).toList();
    return SingleChildScrollView(
      child: Padding(padding: EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(height: 40),
        Container(padding: EdgeInsets.symmetric(horizontal: 18, vertical: 16), decoration: BoxDecoration(gradient: LinearGradient(colors: [Color(0xFFD4FF5A), Color(0xFF8BC34A)]), borderRadius: BorderRadius.circular(24)), child: Row(children: [Text("दैनिक खर्च - PREMIUM", style: GoogleFonts.poppins(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.black)), Spacer(), GestureDetector(onTap: (){ Navigator.pushReplacement(context, MaterialPageRoute(builder: (_)=> LoginGate())); }, child: Icon(Icons.logout_rounded, color: Colors.black, size: 20))])),
        SizedBox(height: 12),
        GestureDetector(onTap: editBudgetDialog, child: Container(padding: EdgeInsets.all(16), decoration: BoxDecoration(color: Color(0xFF12151E), borderRadius: BorderRadius.circular(20), border: Border.all(color: Color(0xFF00E676).withOpacity(0.15))), child: Column(children: [Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text("आजचा खर्च", style: TextStyle(color: Colors.white54, fontSize: 11)), Text("₹${today.toInt()}", style: GoogleFonts.poppins(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 22))])), Container(width: 1, height: 44, color: Colors.white10), Expanded(child: Padding(padding: EdgeInsets.only(left: 14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text("शिल्लक", style: TextStyle(color: Colors.white54, fontSize: 11)), Text("₹${remaining.toInt()}", style: GoogleFonts.poppins(color: Color(0xFF00E676), fontWeight: FontWeight.bold, fontSize: 22))]))),]), SizedBox(height: 12), ClipRRect(borderRadius: BorderRadius.circular(10), child: LinearProgressIndicator(value: perc, minHeight: 8, backgroundColor: Colors.white10, valueColor: AlwaysStoppedAnimation(perc>0.8?Colors.redAccent:Color(0xFF00E676))))]))),
        SizedBox(height: 16),
        GridView.builder(physics: NeverScrollableScrollPhysics(), shrinkWrap: true, gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.6), itemCount: catBlocks.length, itemBuilder: (c,i){ var b=catBlocks[i]; return GestureDetector(onTap: ()=> openManualEntry(b), child: Container(padding: EdgeInsets.all(14), decoration: BoxDecoration(gradient: LinearGradient(colors: [Color(b['c1']), Color(b['c2'])], begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: BorderRadius.circular(20)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(b['icon'], style: TextStyle(fontSize: 28)), Spacer(), Text(b['title'], style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13))]))); }),
        SizedBox(height: 16),
        Text("आजचे व्यवहार", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
       ...todaysList.map((e)=> ListTile(onTap: ()=> showListOptions(exps.indexOf(e), e), leading: CircleAvatar(backgroundColor: Color(0xFF1A1F2E), child: Text("₹", style: TextStyle(color: Colors.white))), title: Text(e.title, style: TextStyle(color: Colors.white, fontSize: 13)), trailing: Text("₹${e.amount}", style: TextStyle(color: Color(0xFF00E676), fontWeight: FontWeight.bold))))
      ])),
    );
  }
  Widget buildLedger(){
    return Padding(padding: EdgeInsets.all(16), child: Column(children: [SizedBox(height: 40), Text("सर्व व्यवहार", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)), Expanded(child: ListView.builder(itemCount: exps.length, itemBuilder: (c,i){ var e=exps[i]; return ListTile(onTap: ()=> showListOptions(i, e), title: Text(e.title, style: TextStyle(color: Colors.white)), subtitle: Text(DateFormat('dd MMM yyyy').format(e.date), style: TextStyle(color: Colors.white38, fontSize: 10)), trailing: Text("₹${e.amount}", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))); }))]));
  }
  Widget buildUdhaari(){
    double totalU = udhars.fold(0, (s,e)=> s + (double.tryParse(e.amount)??0));
    return Padding(padding: EdgeInsets.all(16), child: Column(children: [SizedBox(height: 40), Container(padding: EdgeInsets.all(16), decoration: BoxDecoration(color: Color(0xFF12151E), borderRadius: BorderRadius.circular(16)), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text("एकूण उधारी", style: TextStyle(color: Colors.white70)), Text("₹${totalU.toInt()}", style: TextStyle(color: Colors.orangeAccent, fontSize: 22, fontWeight: FontWeight.bold))])), SizedBox(height: 12), Expanded(child: ListView.builder(itemCount: udhars.length, itemBuilder: (c,i){ var u=udhars[i]; return ListTile(title: Text(u.name, style: TextStyle(color: Colors.white)), subtitle: Text(u.type, style: TextStyle(color: Colors.white38, fontSize: 11)), trailing: Text("₹${u.amount}", style: TextStyle(color: Colors.orangeAccent))); }))] ));
  }
  Widget buildGraphPage(){
    Map<String,double> catSum={}; for(var e in exps){ catSum[e.cat]=(catSum[e.cat]??0)+(double.tryParse(e.amount)??0); }
    return Padding(padding: EdgeInsets.all(16), child: Column(children: [SizedBox(height: 40), Text("Analytics", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)), SizedBox(height: 20), Container(height: 200, padding: EdgeInsets.all(16), decoration: BoxDecoration(color: Color(0xFF12151E), borderRadius: BorderRadius.circular(20)), child: PieChart(PieChartData(sections: catSum.entries.map((en){ int idx=catBlocks.indexWhere((b)=>b['cat']==en.key); return PieChartSectionData(value: en.value, title: en.key, color: idx>=0?Color(catBlocks[idx]['c1']):Colors.grey, radius: 60, titleStyle: TextStyle(fontSize: 10, color: Colors.white)); }).toList())))]));
  }
}
