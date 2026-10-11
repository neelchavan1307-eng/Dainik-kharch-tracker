import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';

void main() => runApp(MaterialApp(debugShowCheckedModeBanner: false, home: LoginGate()));

// FIX: Aata kayam Lock yenaar
class LoginGate extends StatefulWidget { @override State<LoginGate> createState()=> _LoginGateState(); }
class _LoginGateState extends State<LoginGate> {
  @override Widget build(BuildContext context){
    return LoginPage(onSuccess: (){
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_)=> DainikKharchApp()));
    });
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
  String statusText = "Unlock your diary";
  Offset? fingerPos;
  late AnimationController pulseCtrl;

  @override void initState(){
    super.initState();
    pulseCtrl = AnimationController(vsync: this, duration: Duration(milliseconds: 1000))..repeat(reverse: true);
    loadPattern();
  }
  @override void dispose(){ pulseCtrl.dispose(); super.dispose(); }

  void loadPattern() async {
    final p = await SharedPreferences.getInstance();
    String? pat = p.getString('userPattern_v2');
    if(pat!=null && pat.isNotEmpty){
      savedPattern = pat.split(',').map((e)=> int.parse(e)).toList();
      setState(()=> statusText = "Draw pattern or use Fingerprint");
    } else {
      setState(()=> isSettingPattern = true);
      setState(()=> statusText = "Set new pattern - Join 4 dots");
    }
  }
  void savePattern(List<int> pat) async {
    final p = await SharedPreferences.getInstance();
    await p.setString('userPattern_v2', pat.join(','));
    HapticFeedback.heavyImpact();
    setState(()=> savedPattern=pat);
    setState(()=> isSettingPattern=false);
    setState(()=> statusText="Pattern saved! Draw again to unlock");
    setState(()=> enteredPattern=[]);
  }
  Future<void> tryFingerprint() async {
    try{
      bool isSupported = await auth.isDeviceSupported();
      if(!isSupported){ setState(()=> statusText="Fingerprint not supported"); return; }
      bool didAuth = await auth.authenticate(
        localizedReason: 'Unlock Kharch Vahi',
        options: AuthenticationOptions(biometricOnly: false, stickyAuth: true, useErrorDialogs: true)
      );
      if(didAuth){ HapticFeedback.heavyImpact(); widget.onSuccess(); }
    } on PlatformException catch(e){ setState(()=> statusText="Enable Fingerprint in Settings"); }
  }

  int? getDotIndex(Offset pos, Size size){
    double cellW = size.width/3; double cellH = size.height/3;
    for(int i=0;i<9;i++){ int row = i ~/ 3; int col = i % 3; Offset center = Offset(col*cellW + cellW/2, row*cellH + cellH/2); if((pos - center).distance < 40) return i; }
    return null;
  }

  @override Widget build(BuildContext context){
    return Scaffold(
      backgroundColor: Color(0xFF070A11),
      body: Stack(children: [
        // Background Glow
        Positioned(top: -100, left: -80, child: Container(width: 250, height: 250, decoration: BoxDecoration(shape: BoxShape.circle, color: Color(0xFF00E676).withOpacity(0.15), boxShadow: [BoxShadow(blurRadius: 80, color: Color(0xFF00E676).withOpacity(0.2))]))),
        Positioned(bottom: -80, right: -60, child: Container(width: 300, height: 300, decoration: BoxDecoration(shape: BoxShape.circle, color: Color(0xFFD4FF5A).withOpacity(0.12))))),

        Center(child: Padding(padding: EdgeInsets.all(20), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          // Modern Glass Logo
          Container(padding: EdgeInsets.all(2), decoration: BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [Color(0xFF00E676), Color(0xFFD4FF5A)])), child: Container(padding: EdgeInsets.all(18), decoration: BoxDecoration(shape: BoxShape.circle, color: Color(0xFF12151E)), child: Icon(Icons.account_balance_wallet_rounded, size: 38, color: Color(0xFF00E676)))),
          SizedBox(height: 16),
          Text("खर्चाची नोंद वही", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 24, letterSpacing: 0.5)),
          SizedBox(height: 6),
          Container(padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: Colors.white.withOpacity(0.07), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white12)), child: Text(statusText, style: TextStyle(color: isSettingPattern? Color(0xFFD4FF5A):Colors.white54, fontSize: 11, fontWeight: FontWeight.w600))),

          SizedBox(height: 28),

          // MODERN PATTERN
          Container(width: 280, height: 280, decoration: BoxDecoration(color: Color(0xFF12151E).withOpacity(0.8), borderRadius: BorderRadius.circular(30), border: Border.all(color: Colors.white.withOpacity(0.06)), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 30, offset: Offset(0,20))]), child: Padding(padding: EdgeInsets.all(20), child: GestureDetector(
            onPanStart: (d){ setState(()=> enteredPattern=[]); },
            onPanUpdate: (d){ Size sz = Size(240,240); int? idx = getDotIndex(d.localPosition, sz); if(idx!=null &&!enteredPattern.contains(idx)){ HapticFeedback.selectionClick(); setState(()=> enteredPattern.add(idx)); fingerPos = d.localPosition; } },
            onPanEnd: (d){ setState(()=> fingerPos=null); if(isSettingPattern){ if(enteredPattern.length<4){ setState(()=> statusText="At least 4 dots needed!"); enteredPattern=[]; } } else { if(enteredPattern.length>=4){ if(savedPattern.isEmpty || enteredPattern.join(',')==savedPattern.join(',')){ HapticFeedback.heavyImpact(); widget.onSuccess(); } else { HapticFeedback.vibrate(); setState(()=> statusText="Wrong pattern! Try again"); Future.delayed(Duration(milliseconds: 400), ()=> setState(()=> enteredPattern=[])); } } } },
            child: CustomPaint(
              painter: ModernPatternPainter(enteredPattern: enteredPattern, fingerPos: fingerPos),
              child: GridView.builder(physics: NeverScrollableScrollPhysics(), gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 18, mainAxisSpacing: 18), itemCount: 9, itemBuilder: (c,i){ bool sel = enteredPattern.contains(i); return AnimatedContainer(duration: Duration(milliseconds: 200), decoration: BoxDecoration(color: sel? Color(0xFF00E676):Color(0xFF1E2330), shape: BoxShape.circle, border: Border.all(color: sel? Color(0xFF00E676):Colors.white.withOpacity(0.08), width: sel?2.5:1), boxShadow: sel? [BoxShadow(color: Color(0xFF00E676).withOpacity(0.5), blurRadius: 18, spreadRadius: 1)]:[]), child: Center(child: Container(width: sel?10:6, height: sel?10:6, decoration: BoxDecoration(color: sel? Colors.black:Colors.white24, shape: BoxShape.circle)))); }),
            ),
          ))),

          SizedBox(height: 18),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            TextButton(onPressed: ()=> setState(()=> enteredPattern=[]), child: Text("Clear", style: TextStyle(color: Colors.white38, fontSize: 12))),
            if(isSettingPattern && enteredPattern.length>=4)...[SizedBox(width: 10), ElevatedButton(onPressed: ()=> savePattern(enteredPattern), style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF00E676), foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10)), child: Text("Save Pattern", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)))],
          ]),

          SizedBox(height: 10),
          Row(children: [Expanded(child: Divider(color: Colors.white10, indent: 40)), Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text("OR", style: TextStyle(color: Colors.white24, fontSize: 10))), Expanded(child: Divider(color: Colors.white10, endIndent: 40))]),
          SizedBox(height: 18),

          // LATEST FINGERPRINT BUTTON WITH PULSE
          ScaleTransition(scale: Tween(begin: 1.0, end: 1.05).animate(pulseCtrl), child: GestureDetector(onTap: tryFingerprint, child: Container(padding: EdgeInsets.symmetric(horizontal: 30, vertical: 16), decoration: BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF1A1F2E), Color(0xFF252B3D)]), borderRadius: BorderRadius.circular(50), border: Border.all(color: Color(0xFF00E676).withOpacity(0.3), width: 1), boxShadow: [BoxShadow(color: Color(0xFF00E676).withOpacity(0.15), blurRadius: 25, offset: Offset(0,8))]), child: Row(mainAxisSize: MainAxisSize.min, children: [Container(padding: EdgeInsets.all(8), decoration: BoxDecoration(color: Color(0xFF00E676).withOpacity(0.15), shape: BoxShape.circle), child: Icon(Icons.fingerprint_rounded, color: Color(0xFF00E676), size: 24)), SizedBox(width: 12), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text("Fingerprint Unlock", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)), Text("Touch the sensor", style: TextStyle(color: Colors.white38, fontSize: 9))])])))),

        ]))),
      ]),
    );
  }
}

class ModernPatternPainter extends CustomPainter {
  final List<int> enteredPattern; final Offset? fingerPos;
  ModernPatternPainter({required this.enteredPattern, this.fingerPos});
  @override void paint(Canvas canvas, Size size){
    if(enteredPattern.isEmpty) return;
    Paint linePaint = Paint()..shader=LinearGradient(colors: [Color(0xFF00E676), Color(0xFFD4FF5A)]).createShader(Rect.fromLTWH(0, 0, size.width, size.height))..strokeWidth=5..style=PaintingStyle.stroke..strokeCap=StrokeCap.round..strokeJoin=StrokeJoin.round;
    Paint glowPaint = Paint()..color=Color(0xFF00E676).withOpacity(0.3)..strokeWidth=12..style=PaintingStyle.stroke..strokeCap=StrokeCap.round..maskFilter=MaskFilter.blur(BlurStyle.normal, 6);
    double cellW = size.width/3; double cellH = size.height/3;
    List<Offset> points = [];
    for(int idx in enteredPattern){ int row = idx ~/ 3; int col = idx % 3; points.add(Offset(col*cellW + cellW/2, row*cellH + cellH/2)); }
    for(int i=0;i<points.length-1;i++){ canvas.drawLine(points[i], points[i+1], glowPaint); canvas.drawLine(points[i], points[i+1], linePaint); }
    if(fingerPos!=null && points.isNotEmpty){ canvas.drawLine(points.last, fingerPos!, linePaint..color=Color(0xFF00E676).withOpacity(0.4)); }
  }
  @override bool shouldRepaint(covariant CustomPainter oldDelegate)=>true;
}

class Expense {
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
class _DState extends State<DainikKharchApp> with WidgetsBindingObserver {
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
  @override void initState(){ super.initState(); WidgetsBinding.instance.addObserver(this); load(); }
  @override void dispose(){ WidgetsBinding.instance.removeObserver(this); super.dispose(); }
  @override void didChangeAppLifecycleState(AppLifecycleState state){
    if(state==AppLifecycleState.paused || state==AppLifecycleState.inactive){
      // App background la gela ki lock kara
    }
    if(state==AppLifecycleState.resumed){
      // Parat aala ki lock dakhva
      // Navigator.pushReplacement(context, MaterialPageRoute(builder: (_)=> LoginGate()));
    }
  }
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
  }  @override Widget build(BuildContext context){
    return Scaffold(
      backgroundColor: Color(0xFF070A11),
      body: tab==0? buildDash() : tab==1? buildLedger() : tab==2? buildUdhaari() : buildGraphPage(),
      bottomNavigationBar: Container(margin: EdgeInsets.all(14), padding: EdgeInsets.all(6), decoration: BoxDecoration(color: Color(0xFF12151E), borderRadius: BorderRadius.circular(28), border: Border.all(color: Colors.white10)), child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [nav(Icons.dashboard_rounded,0), nav(Icons.receipt_long_rounded,1), nav(Icons.handshake_rounded,2), nav(Icons.bar_chart_rounded,3)])),
    );
  }
  Widget nav(IconData ic,int idx){ bool s=tab==idx; return GestureDetector(onTap: ()=>setState(()=>tab=idx), child: AnimatedContainer(duration: Duration(milliseconds: 250), padding: EdgeInsets.symmetric(horizontal: 22, vertical: 12), decoration: BoxDecoration(color: s?Color(0xFF00E676):Colors.transparent, borderRadius: BorderRadius.circular(20), boxShadow: s? [BoxShadow(color: Color(0xFF00E676).withOpacity(0.3), blurRadius: 15)]:[]), child: Icon(ic, color: s?Colors.black:Colors.white38, size: 22))); }
  Widget buildDash(){
    double today=0; for(var e in exps){ if(sameDay(e.date, selDate)) today+= double.tryParse(e.amount)??0; }
    double perc = (today/monthlyBudget).clamp(0,1);
    double remaining = monthlyBudget - today;
    var todaysList = exps.where((e)=>sameDay(e.date, selDate)).toList();
    return CustomScrollView(slivers: [
      SliverAppBar(expandedHeight: 380, pinned: true, backgroundColor: Color(0xFF070A11), flexibleSpace: FlexibleSpaceBar(background: Stack(children: [
        Positioned(left: 16,right: 16,top: 55, child: Container(padding: EdgeInsets.all(16), decoration: BoxDecoration(gradient: LinearGradient(colors: [Color(0xFFD4FF5A), Color(0xFF8BC34A)]), borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Color(0xFFD4FF5A).withOpacity(0.2), blurRadius: 20)]), child: Row(children: [Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text("दैनिक खर्च - PREMIUM 3D", style: GoogleFonts.poppins(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.black)), Text("Secure + Modern Lock Active ✓", style: TextStyle(fontSize: 10, color: Colors.black87, fontWeight: FontWeight.bold))]), Spacer(), GestureDetector(onTap: () async { Navigator.pushReplacement(context, MaterialPageRoute(builder: (_)=> LoginGate())); }, child: Container(padding: EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.black, shape: BoxShape.circle), child: Icon(Icons.logout_rounded, color: Color(0xFFD4FF5A), size: 18))) ]))),
        Positioned(left: 16,right: 16,bottom: 10, child: GestureDetector(onTap: editBudgetDialog, child: Container(padding: EdgeInsets.all(16), decoration: BoxDecoration(color: Color(0xFF12151E), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withOpacity(0.05))), child: Column(children: [Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text("आजचा खर्च", style: TextStyle(color: Colors.white38, fontSize: 10)), Text("₹${today.toInt()}", style: GoogleFonts.poppins(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 22))])), Container(width: 1, height: 40, color: Colors.white10), Expanded(child: Padding(padding: EdgeInsets.only(left: 14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Text("शिल्लक", style: TextStyle(color: Colors.white38, fontSize: 10)), SizedBox(width: 4), Icon(Icons.edit, size: 10, color: Color(0xFF00E676))]), Text("₹${remaining.toInt()}", style: GoogleFonts.poppins(color: Color(0xFF00E676), fontWeight: FontWeight.bold, fontSize: 22))]))),]), SizedBox(height: 12), ClipRRect(borderRadius: BorderRadius.circular(10), child: LinearProgressIndicator(value: perc, minHeight: 8, backgroundColor: Colors.white.withOpacity(0.06), valueColor: AlwaysStoppedAnimation(perc>0.8? Colors.redAccent : Color(0xFF00E676)))), SizedBox(height: 6), Text("बजेट: ₹${monthlyBudget.toInt()} • Tap to edit", style: TextStyle(color: Colors.white38, fontSize: 10))])))),
      ]))),
      SliverToBoxAdapter(child: Padding(padding: EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text("Categories", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
        SizedBox(height: 14),
        GridView.builder(shrinkWrap: true, physics: NeverScrollableScrollPhysics(), gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, childAspectRatio: 0.92, crossAxisSpacing: 12, mainAxisSpacing: 12), itemCount: catBlocks.length, itemBuilder: (c,i){ var q = catBlocks[i]; return GestureDetector(onTap: ()=> openManualEntry(q), child: Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(q['c1']), Color(q['c2'])]), borderRadius: BorderRadius.circular(22), boxShadow: [BoxShadow(color: Color(q['c1']).withOpacity(0.3), blurRadius: 15, offset: Offset(0,8))]), child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Text(q['icon'].toString(), style: TextStyle(fontSize: 28)), SizedBox(height: 8), Text(q['title'].toString(), style: GoogleFonts.poppins(fontWeight: FontWeight.w800, fontSize: 11, color: Colors.white), textAlign: TextAlign.center)])))); }),
        SizedBox(height: 22),
        Row(children: [Text("Today's entries", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)), Spacer(), Text("${todaysList.length} items", style: TextStyle(color: Colors.white24, fontSize: 10))]),
        SizedBox(height: 10),
        todaysList.isEmpty? Container(padding: EdgeInsets.all(24), decoration: BoxDecoration(color: Color(0xFF12151E), borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.white.withOpacity(0.04))), child: Center(child: Column(children: [Icon(Icons.add_circle_outline, color: Colors.white24), SizedBox(height: 8), Text("No expenses yet - Tap blocks above", style: TextStyle(color: Colors.white38, fontSize: 11))])) ) :
        Column(children: todaysList.map((e){ int realIdx = exps.indexOf(e); return GestureDetector(onTap: ()=> showListOptions(realIdx, e), child: Container(margin: EdgeInsets.symmetric(vertical: 5), padding: EdgeInsets.all(14), decoration: BoxDecoration(color: Color(0xFF12151E), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withOpacity(0.04))), child: Row(children: [Container(width: 42, height: 42, decoration: BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF00E676), Color(0xFF69F0AE)]), shape: BoxShape.circle), child: Center(child: Text(e.cat.isNotEmpty? e.cat[0]:"₹", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)))), SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(e.title, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)), Text("${e.cat} • ${DateFormat('hh:mm a').format(e.date)}", style: TextStyle(color: Colors.white38, fontSize: 10))])), Container(padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(20)), child: Text("₹${e.amount}", style: TextStyle(color: Color(0xFF00E676), fontWeight: FontWeight.w900, fontSize: 13)))]))); }).toList()),
        SizedBox(height: 90),
      ])))
    ]);
  }
  Widget buildGraphPage(){
    Map<String, double> catTotals = {};
    for(var e in exps){ catTotals[e.cat] = (catTotals[e.cat]??0) + (double.tryParse(e.amount)??0); }
    double total = catTotals.values.fold(0, (a,b)=>a+b);
    List<Color> colors = [Color(0xFF00C853), Color(0xFFD500F9), Color(0xFF2962FF), Color(0xFFFF6D00), Color(0xFF00B8D4), Color(0xFFFF1744), Color(0xFF6C757D)];
    return Scaffold(backgroundColor: Color(0xFF070A11), appBar: AppBar(backgroundColor: Color(0xFF070A11), title: Text("Analytics", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)), iconTheme: IconThemeData(color: Colors.white)), body: SingleChildScrollView(padding: EdgeInsets.all(16), child: Column(children: [
      Container(padding: EdgeInsets.all(18), decoration: BoxDecoration(color: Color(0xFF12151E), borderRadius: BorderRadius.circular(22), border: Border.all(color: Colors.white.withOpacity(0.05))), child: Column(children: [Text("Total: ₹${total.toInt()} / ₹${monthlyBudget.toInt()}", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)), SizedBox(height: 16), SizedBox(height: 200, child: catTotals.isEmpty? Center(child: Text("No data", style: TextStyle(color: Colors.white38))) : PieChart(PieChartData(sectionsSpace: 3, centerSpaceRadius: 45, sections: catTotals.entries.map((en){ int idx = catTotals.keys.toList().indexOf(en.key); Color col = colors[idx % colors.length]; double perc = total==0?0: en.value/total*100; return PieChartSectionData(color: col, value: en.value, title: "${perc.toStringAsFixed(0)}%", radius: 65, titleStyle: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)); }).toList()))),])),
      SizedBox(height: 16),
      Container(padding: EdgeInsets.all(18), decoration: BoxDecoration(color: Color(0xFF12151E), borderRadius: BorderRadius.circular(22)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text("Last 7 days", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)), SizedBox(height: 16), SizedBox(height: 180, child: BarChart(BarChartData(barGroups: List.generate(7, (i){ DateTime d = DateTime.now().subtract(Duration(days: 6-i)); double sum=0; for(var e in exps){ if(sameDay(e.date, d)) sum+= double.tryParse(e.amount)??0; } return BarChartGroupData(x:i, barRods: [BarChartRodData(toY: sum, color: Color(0xFF00E676), width: 16, borderRadius: BorderRadius.circular(6))]); }), titlesData: FlTitlesData(bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, _){ return Padding(padding: EdgeInsets.only(top: 6), child: Text(DateFormat('dd').format(DateTime.now().subtract(Duration(days: 6-v.toInt()))), style: TextStyle(color: Colors.white38, fontSize: 10))); }))), gridData: FlGridData(show: false), borderData: FlBorderData(show: false),)))])),
    ])));
  }
  Widget buildUdhaari(){
    double totalDen=0, totalGhet=0; for(var u in udhars){ if(u.type=="देणे") totalDen+= double.tryParse(u.amount)??0; else totalGhet+= double.tryParse(u.amount)??0; }
    return Scaffold(backgroundColor: Color(0xFF070A11), appBar: AppBar(backgroundColor: Color(0xFF070A11), title: Text("Udhaari", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)), actions: [IconButton(onPressed: showUdhaariAdd, icon: Icon(Icons.add_rounded, color: Color(0xFF00E676)))]),
      body: Column(children: [Padding(padding: EdgeInsets.all(16), child: Row(children: [Expanded(child: Container(padding: EdgeInsets.all(14), decoration: BoxDecoration(color: Color(0xFF12151E), borderRadius: BorderRadius.circular(16)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text("द्यायचे", style: TextStyle(color: Colors.white38, fontSize: 10)), SizedBox(height: 4), Text("₹${totalDen.toInt()}", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 18))]))), SizedBox(width: 12), Expanded(child: Container(padding: EdgeInsets.all(14), decoration: BoxDecoration(color: Color(0xFF12151E), borderRadius: BorderRadius.circular(16)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text("यायचे", style: TextStyle(color: Colors.white38, fontSize: 10)), SizedBox(height: 4), Text("₹${totalGhet.toInt()}", style: TextStyle(color: Color(0xFF00E676), fontWeight: FontWeight.bold, fontSize: 18))]))),])), Expanded(child: ListView(children: udhars.map((u)=> Container(margin: EdgeInsets.symmetric(horizontal: 16, vertical: 6), padding: EdgeInsets.all(14), decoration: BoxDecoration(color: Color(0xFF12151E), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withOpacity(0.03))), child: Row(children: [CircleAvatar(backgroundColor: u.type=="देणे"?Colors.redAccent:Color(0xFF00E676), child: Text(u.name.isNotEmpty?u.name[0].toUpperCase():"?", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))), SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(u.name, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)), Text(u.type, style: TextStyle(color: Colors.white38, fontSize: 10))])), Text("₹${u.amount}", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)), IconButton(onPressed: (){ setState(()=> udhars.remove(u)); save(); }, icon: Icon(Icons.delete_outline, color: Colors.white24, size: 18))]))).toList())),])
    );
  }
  void showUdhaariAdd(){
    String name=""; String amt=""; String type="देणे";
    showDialog(context: context, builder: (c)=> StatefulBuilder(builder: (c2,setS)=> AlertDialog(backgroundColor: Color(0xFF12151E), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), title: Text("Udhaari", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)), content: Column(mainAxisSize: MainAxisSize.min, children: [TextField(decoration: InputDecoration(labelText: "नाव", filled: true, fillColor: Colors.white.withOpacity(0.05), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)), style: TextStyle(color: Colors.white), onChanged: (v)=>name=v), SizedBox(height: 10), TextField(decoration: InputDecoration(labelText: "रक्कम", filled: true, fillColor: Colors.white.withOpacity(0.05), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)), style: TextStyle(color: Colors.white), keyboardType: TextInputType.number, onChanged: (v)=>amt=v), SizedBox(height: 10), DropdownButton<String>(value: type, dropdownColor: Color(0xFF12151E), style: TextStyle(color: Colors.white), isExpanded: true, items: ["देणे","घेणे"].map((e)=>DropdownMenuItem(value:e, child: Text(e))).toList(), onChanged: (v)=>setS(()=>type=v!)),]), actions: [ElevatedButton(onPressed: (){ if(name.isNotEmpty && amt.isNotEmpty){ setState(()=> udhars.insert(0, Udhaari(name:name, amount:amt, type:type, date:DateTime.now()))); save(); Navigator.pop(c); } }, style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF00E676), foregroundColor: Colors.black), child: Text("Save", style: TextStyle(fontWeight: FontWeight.bold))) ] )));
  }
  Widget buildLedger(){
    return Scaffold(backgroundColor: Color(0xFF070A11), appBar: AppBar(backgroundColor: Color(0xFF070A11), title: Text("All Entries", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold))), body: exps.isEmpty? Center(child: Text("No entries", style: TextStyle(color: Colors.white38))): ListView.builder(padding: EdgeInsets.all(12), itemCount: exps.length, itemBuilder: (c,i){ var e=exps[i]; return Container(margin: EdgeInsets.symmetric(vertical: 4), padding: EdgeInsets.all(14), decoration: BoxDecoration(color: Color(0xFF12151E), borderRadius: BorderRadius.circular(14)), child: Row(children: [Expanded(child: Text(e.title, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500))), Text("₹${e.amount}", style: TextStyle(color: Color(0xFF00E676), fontWeight: FontWeight.bold))])); }));
  }
}
