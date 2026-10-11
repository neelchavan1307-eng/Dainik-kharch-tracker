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
  bool isLogged = false;
  @override void initState(){ super.initState(); checkLogin(); }
  void checkLogin() async {
    final p = await SharedPreferences.getInstance();
    bool logged = p.getBool('isLogged')?? false;
    if(logged) setState(()=> isLogged=true);
  }
  @override Widget build(BuildContext context){
    return isLogged? DainikKharchApp() : LoginPage(onSuccess: ()=> setState(()=> isLogged=true));
  }
}

class LoginPage extends StatefulWidget {
  final VoidCallback onSuccess;
  LoginPage({required this.onSuccess});
  @override State<LoginPage> createState()=> _LoginPageState();
}
class _LoginPageState extends State<LoginPage> {
  final LocalAuthentication auth = LocalAuthentication();
  List<int> enteredPattern = [];
  List<int> savedPattern = [];
  bool isSettingPattern = false;
  String statusText = "पॅटर्न काढा किंवा फिंगरप्रिंट लावा";
  Offset? fingerPos;

  @override void initState(){ super.initState(); loadPattern(); }
  void loadPattern() async {
    final p = await SharedPreferences.getInstance();
    String? pat = p.getString('userPattern');
    if(pat!=null && pat.isNotEmpty){
      savedPattern = pat.split(',').map((e)=> int.parse(e)).toList();
      setState(()=> statusText = "पॅटर्न काढा किंवा फिंगरप्रिंट लावा");
    } else {
      setState(()=> isSettingPattern = true);
      setState(()=> statusText = "नवीन पॅटर्न सेट करा - 4 ठिपके जोडा");
    }
  }
  void savePattern(List<int> pat) async {
    final p = await SharedPreferences.getInstance();
    await p.setString('userPattern', pat.join(','));
    setState(()=> savedPattern=pat);
    setState(()=> isSettingPattern=false);
    setState(()=> statusText="पॅटर्न सेव झाला! आता तोच काढा");
    setState(()=> enteredPattern=[]);
  }
  Future<void> tryFingerprint() async {
    try{
      bool canCheck = await auth.canCheckBiometrics;
      bool isSupported = await auth.isDeviceSupported();
      if(!canCheck ||!isSupported){ setState(()=> statusText="फिंगरप्रिंट सपोर्ट नाही, Setting मध्ये ON करा"); return; }
      bool didAuth = await auth.authenticate(localizedReason: 'खर्च वही उघडण्यासाठी फिंगरप्रिंट लावा', options: AuthenticationOptions(biometricOnly: true, stickyAuth: true, useErrorDialogs: true));
      if(didAuth) loginSuccess();
    } on PlatformException catch(e){ setState(()=> statusText="Error: ${e.message}"); }
  }
  void loginSuccess() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool('isLogged', true);
    widget.onSuccess();
  }
  int? getDotIndex(Offset pos, Size size){
    double cellW = size.width/3; double cellH = size.height/3;
    for(int i=0;i<9;i++){ int row = i ~/ 3; int col = i % 3; Offset center = Offset(col*cellW + cellW/2, row*cellH + cellH/2); if((pos - center).distance < 35) return i; }
    return null;
  }

  @override Widget build(BuildContext context){
    return Scaffold(
      backgroundColor: Color(0xFF0B0E14),
      body: Center(child: Padding(padding: EdgeInsets.all(20), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(padding: EdgeInsets.all(20), decoration: BoxDecoration(gradient: LinearGradient(colors: [Color(0xFFD4FF5A), Color(0xFF8BC34A)]), shape: BoxShape.circle), child: Text("₹", style: TextStyle(fontSize: 40, fontWeight: FontWeight.w900))),
        SizedBox(height: 14),
        Text("खर्चाची नोंद वही", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22)),
        SizedBox(height: 8),
        Text(statusText, textAlign: TextAlign.center, style: TextStyle(color: isSettingPattern? Color(0xFFFFEB3B) : Colors.white54, fontSize: 12, fontWeight: FontWeight.bold)),
        SizedBox(height: 20),
        Container(width: 260, height: 260, child: GestureDetector(
          onPanStart: (d){ setState(()=> enteredPattern=[]); },
          onPanUpdate: (d){ Size sz = Size(260,260); int? idx = getDotIndex(d.localPosition, sz); if(idx!=null &&!enteredPattern.contains(idx)){ setState(()=> enteredPattern.add(idx)); fingerPos = d.localPosition; } },
          onPanEnd: (d){ setState(()=> fingerPos=null); if(isSettingPattern){ if(enteredPattern.length<4){ setState(()=> statusText="किमान 4 ठिपके जोडा!"); enteredPattern=[]; } } else { if(enteredPattern.length>=4){ if(enteredPattern.join(',')==savedPattern.join(',')) loginSuccess(); else { setState(()=> statusText="चुकीचा पॅटर्न!"); Future.delayed(Duration(milliseconds: 500), ()=> setState(()=> enteredPattern=[])); } } } },
          child: CustomPaint(
            painter: PatternPainter(enteredPattern: enteredPattern, fingerPos: fingerPos),
            child: GridView.builder(physics: NeverScrollableScrollPhysics(), gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 25, mainAxisSpacing: 25), itemCount: 9, itemBuilder: (c,i){ bool sel = enteredPattern.contains(i); return Container(decoration: BoxDecoration(color: sel? Color(0xFF00E676):Color(0xFF1A1F2B), shape: BoxShape.circle, border: Border.all(color: sel? Color(0xFF00E676):Colors.white24, width: 2)), child: Center(child: Container(width: sel?14:8, height: sel?14:8, decoration: BoxDecoration(color: sel? Colors.black:Colors.white24, shape: BoxShape.circle)))); }),
          ),
        )),
        SizedBox(height: 10),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          TextButton(onPressed: ()=> setState(()=> enteredPattern=[]), child: Text("Clear करा", style: TextStyle(color: Colors.white54))),
          SizedBox(width: 10),
          if(isSettingPattern && enteredPattern.length>=4) ElevatedButton(onPressed: ()=> savePattern(enteredPattern), child: Text("Save करा"), style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF00E676), foregroundColor: Colors.black)),
        ]),
        SizedBox(height: 18),
        GestureDetector(onTap: tryFingerprint, child: Container(padding: EdgeInsets.symmetric(horizontal: 28, vertical: 16), decoration: BoxDecoration(color: Color(0xFF1A1F2B), borderRadius: BorderRadius.circular(30), border: Border.all(color: Color(0xFF00E676), width: 1.5)), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.fingerprint, color: Color(0xFF00E676), size: 32), SizedBox(width: 12), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text("फिंगरप्रिंटने उघडा", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)), Text("On-screen साठी Tap करा", style: TextStyle(color: Colors.white38, fontSize: 9))])]))),
        SizedBox(height: 12),
        TextButton(onPressed: loginSuccess, child: Text("Skip (Testing)", style: TextStyle(color: Colors.white24, fontSize: 10))),
      ]))),
    );
  }
}

class PatternPainter extends CustomPainter {
  final List<int> enteredPattern; final Offset? fingerPos;
  PatternPainter({required this.enteredPattern, this.fingerPos});
  @override void paint(Canvas canvas, Size size){
    if(enteredPattern.isEmpty) return;
    Paint linePaint = Paint()..color=Color(0xFF00E676)..strokeWidth=4..style=PaintingStyle.stroke..strokeCap=StrokeCap.round;
    double cellW = size.width/3; double cellH = size.height/3;
    List<Offset> points = [];
    for(int idx in enteredPattern){ int row = idx ~/ 3; int col = idx % 3; points.add(Offset(col*cellW + cellW/2, row*cellH + cellH/2)); }
    for(int i=0;i<points.length-1;i++){ canvas.drawLine(points[i], points[i+1], linePaint); }
    if(fingerPos!=null && points.isNotEmpty){ canvas.drawLine(points.last, fingerPos!, linePaint..color=Color(0xFF00E676).withOpacity(0.5)); }
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
class _DState extends State<DainikKharchApp> {
  List<Expense> exps = []; List<Udhaari> udhars = [];
  DateTime selDate = DateTime.now(); int tab = 0;
  double monthlyBudget = 4000;
  List<Map<String, dynamic>> catBlocks = [
    {"title":"भाजीपाला","icon":"🥬","cat":"भाजीपाला","c1":0xFF00C853,"c2":0xFF69F0AE,"shadow":0xFF00C853},
    {"title":"किराणा","icon":"🛒","cat":"किराणा","c1":0xFFD500F9,"c2":0xFFEA80FC,"shadow":0xFFAA00FF},
    {"title":"पेट्रोल","icon":"⛽","cat":"प्रवास","c1":0xFF2962FF,"c2":0xFF82B1FF,"shadow":0xFF2962FF},
    {"title":"लाईट बिल","icon":"💡","cat":"बिल","c1":0xFFFF6D00,"c2":0xFFFFAB40,"shadow":0xFFFF6D00},
    {"title":"रिचार्ज","icon":"📱","cat":"रिचार्ज","c1":0xFF00B8D4,"c2":0xFF84FFFF,"shadow":0xFF00B8D4},
    {"title":"चहा नाश्ता","icon":"☕","cat":"खाद्य","c1":0xFFFF1744,"c2":0xFFFF8A80,"shadow":0xFFFF1744},
    {"title":"इतर","icon":"➕","cat":"इतर","c1":0xFF6C757D,"c2":0xFFADB5BD,"shadow":0xFF495057},
  ];
  @override void initState(){ super.initState(); load(); }
  Future<void> load() async { final p = await SharedPreferences.getInstance(); var s = p.getString('ex'); if(s!=null) exps = (jsonDecode(s) as List).map((e)=>Expense.fromJson(e)).toList(); var u = p.getString('ud'); if(u!=null) udhars = (jsonDecode(u) as List).map((e)=>Udhaari.fromJson(e)).toList(); var b = p.getDouble('budget'); if(b!=null) monthlyBudget=b; setState((){}); }
  Future<void> save() async { final p = await SharedPreferences.getInstance(); p.setString('ex', jsonEncode(exps.map((e)=>e.toJson()).toList())); p.setString('ud', jsonEncode(udhars.map((e)=>e.toJson()).toList())); p.setDouble('budget', monthlyBudget); }
  bool sameDay(DateTime a,b) => a.year==b.year && a.month==b.month && a.day==b.day;
  void addExp(String t,String a,String c){ setState(()=> exps.insert(0, Expense(title:t, amount:a, cat:c, date:selDate))); save(); }
  void editBudgetDialog(){
    TextEditingController bCtrl = TextEditingController(text: monthlyBudget.toInt().toString());
    showDialog(context: context, builder: (ctx)=> AlertDialog(backgroundColor: Color(0xFF1E2635), title: Text("बजेट टाका", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)), content: TextField(controller: bCtrl, keyboardType: TextInputType.number, style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold), decoration: InputDecoration(prefixText: "₹ ", filled: true, fillColor: Colors.white10, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))), actions: [TextButton(onPressed: ()=>Navigator.pop(ctx), child: Text("रद्द")), ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF00E676)), onPressed: (){ if(bCtrl.text.isNotEmpty){ setState(()=> monthlyBudget = double.tryParse(bCtrl.text)??4000); save(); Navigator.pop(ctx); } }, child: Text("Save", style: TextStyle(color: Colors.black)))],));
  }
  void showListOptions(int index, Expense e){
    TextEditingController tCtrl = TextEditingController(text: e.title);
    TextEditingController aCtrl = TextEditingController(text: e.amount);
    showModalBottomSheet(context: context, backgroundColor: Color(0xFF1A1F2B), shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))), builder: (ctx)=> Padding(padding: EdgeInsets.all(20), child: Column(mainAxisSize: MainAxisSize.min, children: [Text("एडिट / डिलीट", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)), SizedBox(height: 14), TextField(controller: tCtrl, style: TextStyle(color: Colors.white), decoration: InputDecoration(labelText: "नाव", filled: true, fillColor: Colors.white10, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))), SizedBox(height: 10), TextField(controller: aCtrl, keyboardType: TextInputType.number, style: TextStyle(color: Colors.white), decoration: InputDecoration(labelText: "रक्कम", filled: true, fillColor: Colors.white10, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))), SizedBox(height: 16), Row(children: [Expanded(child: ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent), icon: Icon(Icons.delete), label: Text("डिलीट"), onPressed: (){ setState(()=> exps.removeAt(index)); save(); Navigator.pop(ctx); })), SizedBox(width: 10), Expanded(child: ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF00E676)), icon: Icon(Icons.save), label: Text("अपडेट"), onPressed: (){ setState(()=> exps[index] = Expense(title: tCtrl.text, amount: aCtrl.text, cat: e.cat, date: e.date)); save(); Navigator.pop(ctx); })),]),])));
  }
  void openManualEntry(Map<String, dynamic> block){
    TextEditingController amtCtrl = TextEditingController();
    TextEditingController noteCtrl = TextEditingController(text: block['title']);
    showDialog(context: context, builder: (ctx)=> Dialog(backgroundColor: Colors.transparent, child: Container(padding: EdgeInsets.all(20), decoration: BoxDecoration(color: Color(0xFF1E2635), borderRadius: BorderRadius.circular(24)), child: Column(mainAxisSize: MainAxisSize.min, children: [Text("${block['title']} खर्च", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)), SizedBox(height: 14), TextField(controller: amtCtrl, keyboardType: TextInputType.number, autofocus: true, style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900), decoration: InputDecoration(prefixText: "₹ ", filled: true, fillColor: Colors.white10, border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none))), SizedBox(height: 10), TextField(controller: noteCtrl, style: TextStyle(color: Colors.white), decoration: InputDecoration(labelText: "तपशील", filled: true, fillColor: Colors.white10, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))), SizedBox(height: 14), ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Color(block['c1'])), onPressed: (){ if(amtCtrl.text.isNotEmpty){ addExp(noteCtrl.text.isEmpty? block['title'] : noteCtrl.text, amtCtrl.text, block['cat']); Navigator.pop(ctx); } }, child: Text("Add करा"))]))));
  }  @override Widget build(BuildContext context){
    return Scaffold(
      backgroundColor: Color(0xFF0B0E14),
      body: tab==0? buildDash() : tab==1? buildLedger() : tab==2? buildUdhaari() : buildGraphPage(),
      bottomNavigationBar: Container(margin: EdgeInsets.all(14), padding: EdgeInsets.all(6), decoration: BoxDecoration(color: Color(0xFF1A1F2B), borderRadius: BorderRadius.circular(28)), child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [nav(Icons.dashboard,0), nav(Icons.receipt_long,1), nav(Icons.handshake,2), nav(Icons.bar_chart,3)])),
    );
  }
  Widget nav(IconData ic,int idx){ bool s=tab==idx; return GestureDetector(onTap: ()=>setState(()=>tab=idx), child: Container(padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12), decoration: BoxDecoration(color: s?Color(0xFF00E676):Colors.transparent, borderRadius: BorderRadius.circular(20)), child: Icon(ic, color: s?Colors.black:Colors.white54))); }
  Widget buildDash(){
    double today=0; for(var e in exps){ if(sameDay(e.date, selDate)) today+= double.tryParse(e.amount)??0; }
    double perc = (today/monthlyBudget).clamp(0,1);
    double remaining = monthlyBudget - today;
    var todaysList = exps.where((e)=>sameDay(e.date, selDate)).toList();
    return CustomScrollView(slivers: [
      SliverAppBar(expandedHeight: 380, pinned: true, backgroundColor: Color(0xFF0B0E14), flexibleSpace: FlexibleSpaceBar(background: Stack(children: [
        Positioned(left: 16,right: 16,top: 55, child: Container(padding: EdgeInsets.all(16), decoration: BoxDecoration(gradient: LinearGradient(colors: [Color(0xFFD4FF5A), Color(0xFF8BC34A)]), borderRadius: BorderRadius.circular(24)), child: Row(children: [Text("दैनिक खर्च - PREMIUM", style: GoogleFonts.poppins(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.black)), Spacer(), GestureDetector(onTap: () async { final p=await SharedPreferences.getInstance(); p.setBool('isLogged', false); Navigator.pushReplacement(context, MaterialPageRoute(builder: (_)=> LoginGate())); }, child: Icon(Icons.logout, color: Colors.black, size: 20))]))),
        Positioned(left: 16,right: 16,bottom: 10, child: GestureDetector(onTap: editBudgetDialog, child: Container(padding: EdgeInsets.all(14), decoration: BoxDecoration(color: Color(0xFF1A1F2B), borderRadius: BorderRadius.circular(18), border: Border.all(color: Color(0xFF00E676).withOpacity(0.2))), child: Column(children: [Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text("आजचा खर्च", style: TextStyle(color: Colors.white54, fontSize: 11)), Text("₹${today.toInt()}", style: GoogleFonts.poppins(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 20))])), Container(width: 1, height: 40, color: Colors.white10), Expanded(child: Padding(padding: EdgeInsets.only(left: 12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text("शिल्लक", style: TextStyle(color: Colors.white54, fontSize: 11)), Text("₹${remaining.toInt()}", style: GoogleFonts.poppins(color: Color(0xFF00E676), fontWeight: FontWeight.bold, fontSize: 20))]))),]), SizedBox(height: 10), ClipRRect(borderRadius: BorderRadius.circular(10), child: LinearProgressIndicator(value: perc, minHeight: 8, backgroundColor: Colors.white10, valueColor: AlwaysStoppedAnimation(perc>0.8? Colors.redAccent : Color(0xFF00E676)))), Text("बजेट: ₹${monthlyBudget.toInt()} (Tap)", style: TextStyle(color: Colors.white54, fontSize: 10))])))),
      ]))),
      SliverToBoxAdapter(child: Padding(padding: EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text("Premium 3D Blocks", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
        SizedBox(height: 14),
        GridView.builder(shrinkWrap: true, physics: NeverScrollableScrollPhysics(), gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, childAspectRatio: 0.95, crossAxisSpacing: 12, mainAxisSpacing: 12), itemCount: catBlocks.length, itemBuilder: (c,i){ var q = catBlocks[i]; return GestureDetector(onTap: ()=> openManualEntry(q), child: Container(decoration: BoxDecoration(gradient: LinearGradient(colors: [Color(q['c1']), Color(q['c2'])]), borderRadius: BorderRadius.circular(22)), child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Text(q['icon'].toString(), style: TextStyle(fontSize: 26)), SizedBox(height: 8), Text(q['title'].toString(), style: GoogleFonts.poppins(fontWeight: FontWeight.w900, fontSize: 11, color: Colors.white), textAlign: TextAlign.center)])))); }),
        SizedBox(height: 20),
        Text("आजच्या नोंदी - Tap=Edit", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
        SizedBox(height: 10),
        todaysList.isEmpty? Container(padding: EdgeInsets.all(20), decoration: BoxDecoration(color: Color(0xFF1A1F2B), borderRadius: BorderRadius.circular(16)), child: Center(child: Text("Block वर टच करून खर्च टाका!", style: TextStyle(color: Colors.white38)))) :
        Column(children: todaysList.map((e){ int realIdx = exps.indexOf(e); return GestureDetector(onTap: ()=> showListOptions(realIdx, e), child: Container(margin: EdgeInsets.symmetric(vertical: 5), padding: EdgeInsets.all(12), decoration: BoxDecoration(color: Color(0xFF1A1F2B), borderRadius: BorderRadius.circular(14)), child: Row(children: [Container(width: 40, height: 40, decoration: BoxDecoration(color: Color(0xFF00E676), shape: BoxShape.circle), child: Center(child: Text(e.cat.isNotEmpty? e.cat[0]:"₹", style: TextStyle(fontWeight: FontWeight.bold)))), SizedBox(width: 10), Expanded(child: Text(e.title, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))), Text("₹${e.amount}", style: TextStyle(color: Color(0xFF00E676), fontWeight: FontWeight.bold))]))); }).toList()),
        SizedBox(height: 80),
      ])))
    ]);
  }
  Widget buildGraphPage(){
    Map<String, double> catTotals = {};
    for(var e in exps){ catTotals[e.cat] = (catTotals[e.cat]??0) + (double.tryParse(e.amount)??0); }
    double total = catTotals.values.fold(0, (a,b)=>a+b);
    List<Color> colors = [Color(0xFF00C853), Color(0xFFD500F9), Color(0xFF2962FF), Color(0xFFFF6D00), Color(0xFF00B8D4), Color(0xFFFF1744), Color(0xFF6C757D)];
    return Scaffold(backgroundColor: Color(0xFF0B0E14), appBar: AppBar(backgroundColor: Color(0xFF0B0E14), title: Text("ग्राफ रिपोर्ट", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold))), body: SingleChildScrollView(padding: EdgeInsets.all(16), child: Column(children: [
      Container(padding: EdgeInsets.all(16), decoration: BoxDecoration(color: Color(0xFF1A1F2B), borderRadius: BorderRadius.circular(20)), child: Column(children: [Text("एकूण: ₹${total.toInt()} | बजेट: ₹${monthlyBudget.toInt()}", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), SizedBox(height: 16), SizedBox(height: 200, child: catTotals.isEmpty? Center(child: Text("अजून खर्च नाही", style: TextStyle(color: Colors.white38))) : PieChart(PieChartData(sectionsSpace: 2, centerSpaceRadius: 40, sections: catTotals.entries.map((en){ int idx = catTotals.keys.toList().indexOf(en.key); Color col = colors[idx % colors.length]; double perc = total==0?0: en.value/total*100; return PieChartSectionData(color: col, value: en.value, title: "${perc.toStringAsFixed(0)}%\n${en.key}", radius: 60, titleStyle: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)); }).toList()))),])),
      SizedBox(height: 16),
      Container(padding: EdgeInsets.all(16), decoration: BoxDecoration(color: Color(0xFF1A1F2B), borderRadius: BorderRadius.circular(20)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text("7 दिवस Bar Graph", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), SizedBox(height: 16), SizedBox(height: 180, child: BarChart(BarChartData(barGroups: List.generate(7, (i){ DateTime d = DateTime.now().subtract(Duration(days: 6-i)); double sum=0; for(var e in exps){ if(sameDay(e.date, d)) sum+= double.tryParse(e.amount)??0; } return BarChartGroupData(x:i, barRods: [BarChartRodData(toY: sum, color: Color(0xFF00E676), width: 14, borderRadius: BorderRadius.circular(4))]); }), titlesData: FlTitlesData(bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, _){ return Text(DateFormat('dd').format(DateTime.now().subtract(Duration(days: 6-v.toInt()))), style: TextStyle(color: Colors.white54, fontSize: 10)); }))), gridData: FlGridData(show: false), borderData: FlBorderData(show: false),)))])),
    ])));
  }
  Widget buildUdhaari(){
    double totalDen=0, totalGhet=0; for(var u in udhars){ if(u.type=="देणे") totalDen+= double.tryParse(u.amount)??0; else totalGhet+= double.tryParse(u.amount)??0; }
    return Scaffold(backgroundColor: Color(0xFF0B0E14), appBar: AppBar(backgroundColor: Color(0xFF0B0E14), title: Text("उधारी", style: TextStyle(color: Colors.white)), actions: [IconButton(onPressed: showUdhaariAdd, icon: Icon(Icons.add, color: Color(0xFF00E676)))]),
      body: Column(children: [Padding(padding: EdgeInsets.all(16), child: Row(children: [Expanded(child: Container(padding: EdgeInsets.all(12), decoration: BoxDecoration(color: Color(0xFF1A1F2B), borderRadius: BorderRadius.circular(12)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text("द्यायचे", style: TextStyle(color: Colors.white54, fontSize: 10)), Text("₹${totalDen.toInt()}", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold))]))), SizedBox(width: 10), Expanded(child: Container(padding: EdgeInsets.all(12), decoration: BoxDecoration(color: Color(0xFF1A1F2B), borderRadius: BorderRadius.circular(12)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text("यायचे", style: TextStyle(color: Colors.white54, fontSize: 10)), Text("₹${totalGhet.toInt()}", style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold))]))),])), Expanded(child: ListView(children: udhars.map((u)=> Container(margin: EdgeInsets.symmetric(horizontal: 16, vertical: 5), padding: EdgeInsets.all(12), decoration: BoxDecoration(color: Color(0xFF1A1F2B), borderRadius: BorderRadius.circular(12)), child: Row(children: [CircleAvatar(backgroundColor: u.type=="देणे"?Colors.red:Colors.green, child: Text(u.name.isNotEmpty?u.name[0]:"?")), SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(u.name, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), Text(u.type, style: TextStyle(color: Colors.white38, fontSize: 10))])), Text("₹${u.amount}", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), IconButton(onPressed: (){ setState(()=> udhars.remove(u)); save(); }, icon: Icon(Icons.delete, color: Colors.white24, size: 18))]))).toList())),])
    );
  }
  void showUdhaariAdd(){
    String name=""; String amt=""; String type="देणे";
    showDialog(context: context, builder: (c)=> StatefulBuilder(builder: (c2,setS)=> AlertDialog(backgroundColor: Color(0xFF1A1F2B), title: Text("उधारी नोंद", style: TextStyle(color: Colors.white)), content: Column(mainAxisSize: MainAxisSize.min, children: [TextField(decoration: InputDecoration(labelText: "नाव", labelStyle: TextStyle(color: Colors.white54)), style: TextStyle(color: Colors.white), onChanged: (v)=>name=v), TextField(decoration: InputDecoration(labelText: "रक्कम", labelStyle: TextStyle(color: Colors.white54)), style: TextStyle(color: Colors.white), keyboardType: TextInputType.number, onChanged: (v)=>amt=v), DropdownButton<String>(value: type, dropdownColor: Color(0xFF1A1F2B), style: TextStyle(color: Colors.white), items: ["देणे","घेणे"].map((e)=>DropdownMenuItem(value:e, child: Text(e))).toList(), onChanged: (v)=>setS(()=>type=v!)),]), actions: [ElevatedButton(onPressed: (){ if(name.isNotEmpty && amt.isNotEmpty){ setState(()=> udhars.insert(0, Udhaari(name:name, amount:amt, type:type, date:DateTime.now()))); save(); Navigator.pop(c); } }, child: Text("जतन करा"), style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF00E676)))])));
  }
  Widget buildLedger(){
    return Scaffold(backgroundColor: Color(0xFF0B0E14), appBar: AppBar(backgroundColor: Color(0xFF0B0E14), title: Text("सर्व नोंदी", style: TextStyle(color: Colors.white))), body: ListView(children: exps.map((e)=> Container(margin: EdgeInsets.symmetric(vertical: 3, horizontal: 10), padding: EdgeInsets.all(12), decoration: BoxDecoration(color: Color(0xFF1A1F2B), borderRadius: BorderRadius.circular(10)), child: Row(children: [Expanded(child: Text(e.title, style: TextStyle(color: Colors.white))), Text("₹${e.amount}", style: TextStyle(color: Color(0xFF00E676), fontWeight: FontWeight.bold))]))).toList()));
  }
}
