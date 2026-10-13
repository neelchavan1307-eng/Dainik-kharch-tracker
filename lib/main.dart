import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';

Map<String, Map<String, String>> appLang = {
  'mr': {'dash': 'दैनिक खर्च - PREMIUM', 'today': 'आजचा खर्च', 'urle': 'उरले', 'budget': 'बजेट', 'list': 'आजची यादी', 'setting': 'सेटिंग', 'lang': 'भाषा निवडा', 'backup': 'बॅकअप घ्या', 'restore': 'रिस्टोर करा', 'noExp': 'आजचा खर्च नाही'},
  'hi': {'dash': 'दैनिक खर्च - PREMIUM', 'today': 'आज का खर्च', 'urle': 'बाकी', 'budget': 'बजट', 'list': 'आज की लिस्ट', 'setting': 'सेटिंग', 'lang': 'भाषा चुनें', 'backup': 'बैकअप लें', 'restore': 'रिस्टोर करें', 'noExp': 'आज कोई खर्च नहीं'},
  'en': {'dash': 'Daily Expense - PREMIUM', 'today': "Today's Expense", 'urle': 'Remaining', 'budget': 'Budget', 'list': "Today's List", 'setting': 'Settings', 'lang': 'Select Language', 'backup': 'Take Backup', 'restore': 'Restore Data', 'noExp': 'No expense today'},
};
String currentLang = 'mr';

void main() => runApp(MaterialApp(debugShowCheckedModeBanner: false, home: LoginGate()));

Widget warliBackground({required Widget child}) {
  return Stack(
    children: [
      Positioned.fill(
        child: Container(
          color: Color(0xFF070A11),
          child: CustomPaint(painter: WarliPainter(), size: Size.infinite),
        ),
      ),
      child,
      Positioned(
        bottom: 0, left: 0, right: 0,
        child: Container(
          color: Colors.black.withOpacity(0.85),
          padding: EdgeInsets.symmetric(vertical: 7),
          child: Text('Created by Pradip Chavan', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 11, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
        ),
      ),
    ],
  );
}

class WarliPainter extends CustomPainter {
  @override void paint(Canvas canvas, Size size) {
    Paint paint = Paint()..color = Colors.white.withOpacity(0.32)..strokeWidth = 1.3..style = PaintingStyle.stroke;
    for (double y = 20; y < size.height; y += 75) {
      for (double x = 15; x < size.width; x += 60) {
        canvas.drawCircle(Offset(x, y), 5.5, paint);
        Path body = Path(); body.moveTo(x, y+6); body.lineTo(x-8, y+22); body.lineTo(x+8, y+22); body.close(); canvas.drawPath(body, paint);
        canvas.drawLine(Offset(x-8, y+12), Offset(x-16, y+8), paint);
        canvas.drawLine(Offset(x+8, y+12), Offset(x+16, y+8), paint);
        canvas.drawLine(Offset(x-4, y+22), Offset(x-7, y+34), paint);
        canvas.drawLine(Offset(x+4, y+22), Offset(x+7, y+34), paint);
      }
    }
  }
  @override bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class LoginGate extends StatefulWidget { @override State<LoginGate> createState()=> _LoginGateState(); }
class _LoginGateState extends State<LoginGate> {
  @override Widget build(BuildContext context){ return LoginPage(onSuccess: (){ Navigator.pushReplacement(context, MaterialPageRoute(builder: (_)=> DainikKharchApp())); }); }
}

class LoginPage extends StatefulWidget {
  final VoidCallback onSuccess; LoginPage({required this.onSuccess});
  @override State<LoginPage> createState()=> _LoginPageState();
}
class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  final LocalAuthentication auth = LocalAuthentication();
  List<int> enteredPattern = []; List<int> savedPattern = []; bool isSettingPattern = false;
  String statusText = "Original sensor la touch kara 👇"; Offset? fingerPos; late AnimationController pulseCtrl;
  @override void initState(){ super.initState(); pulseCtrl = AnimationController(vsync: this, duration: Duration(milliseconds: 1200))..repeat(reverse: true); loadPattern(); WidgetsBinding.instance.addPostFrameCallback((_) => tryFingerprint()); }
  @override void dispose(){ pulseCtrl.dispose(); super.dispose(); }
  void loadPattern() async {
    final p = await SharedPreferences.getInstance(); String? pat = p.getString('userPattern_v2');
    if(pat!=null && pat.isNotEmpty){ savedPattern = pat.split(',').map((e)=> int.parse(e)).toList(); setState(()=> statusText = "Pattern kinva Original Sensor 👇"); }
    else { setState(()=> isSettingPattern = true); setState(()=> statusText = "Set pattern - Join 4 dots"); }
  }
  void savePattern(List<int> pat) async {
    final p = await SharedPreferences.getInstance(); await p.setString('userPattern_v2', pat.join(',')); HapticFeedback.heavyImpact();
    setState(()=> savedPattern=pat); isSettingPattern=false; statusText="Pattern saved!"; enteredPattern=[];
  }
  Future<void> tryFingerprint() async {
    try{
      bool canCheck = await auth.canCheckBiometrics; bool isSupported = await auth.isDeviceSupported();
      List<BiometricType> available = await auth.getAvailableBiometrics();
      if(!isSupported ||!canCheck){ setState(()=> statusText="Device doesn't support"); return; }
      if(available.isEmpty){ setState(()=> statusText="Fingerprint not enrolled"); return; }
      bool didAuth = await auth.authenticate(localizedReason: 'खर्च वही अनलॉक', options: AuthenticationOptions(biometricOnly: true, stickyAuth: true, useErrorDialogs: true));
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
      body: warliBackground(
        child: SafeArea(
          child: Stack(children: [
            Positioned(top: -60, left: -50, child: Container(width: 180, height: 180, decoration: BoxDecoration(shape: BoxShape.circle, color: Color(0xFF00E676).withOpacity(0.10)))),
            SingleChildScrollView(
              child: Padding(padding: EdgeInsets.only(bottom: 180, top: 20), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Center(child: Container(padding: EdgeInsets.all(2), decoration: BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [Color(0xFF00E676), Color(0xFFD4FF5A)])), child: Container(padding: EdgeInsets.all(14), decoration: BoxDecoration(shape: BoxShape.circle, color: Color(0xFF12151E)), child: Icon(Icons.wallet, size: 32, color: Color(0xFF00E676))))),
                SizedBox(height: 12), Text("खर्चाची नोंद वही", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 22)),
                SizedBox(height: 6), Container(padding: EdgeInsets.symmetric(horizontal: 14, vertical: 6), decoration: BoxDecoration(color: Colors.white.withOpacity(0.06), borderRadius: BorderRadius.circular(20)), child: Text(statusText, style: TextStyle(color: Colors.white70, fontSize: 11))),
                SizedBox(height: 20),
                Center(child: Container(width: 300, height: 340, decoration: BoxDecoration(color: Color(0xFF12151E), borderRadius: BorderRadius.circular(28), border: Border.all(color: Colors.white.withOpacity(0.08))), child: Padding(padding: EdgeInsets.all(16), child: GestureDetector(
                  onPanStart: (d){ setState(()=> enteredPattern=[]); },
                  onPanUpdate: (d){ Size sz=Size(268, 308); int? idx=getDotIndex(d.localPosition, sz); if(idx!=null &&!enteredPattern.contains(idx)){ HapticFeedback.selectionClick(); setState(()=> enteredPattern.add(idx)); fingerPos=d.localPosition; } },
                  onPanEnd: (d){ setState(()=> fingerPos=null); if(isSettingPattern){ if(enteredPattern.length<4){ setState(()=> statusText="At least 4 dots!"); enteredPattern=[]; } } else { if(enteredPattern.length>=4){ if(savedPattern.isEmpty || enteredPattern.join(',')==savedPattern.join(',')){ widget.onSuccess(); } else { HapticFeedback.vibrate(); setState(()=> statusText="Wrong pattern!"); Future.delayed(Duration(milliseconds: 400), ()=> setState(()=> enteredPattern=[])); } } } },
                  child: CustomPaint(painter: ModernPatternPainter(enteredPattern: enteredPattern, fingerPos: fingerPos), child: GridView.builder(physics: NeverScrollableScrollPhysics(), gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 14, mainAxisSpacing: 14, childAspectRatio: 1), itemCount: 9, itemBuilder: (c,i){ bool sel=enteredPattern.contains(i); return Container(decoration: BoxDecoration(color: sel?Color(0xFF00E676):Color(0xFF1E2330), shape: BoxShape.circle, border: Border.all(color: sel?Color(0xFF00E676):Colors.white12, width: sel?2.5:1)), child: Center(child: Container(width: sel?12:6, height: sel?12:6, decoration: BoxDecoration(color: sel?Colors.black:Colors.white24, shape: BoxShape.circle)))); }),
                  ),
                )))),
                SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  TextButton(onPressed: ()=> setState(()=> enteredPattern=[]), child: Text("Clear", style: TextStyle(color: Colors.white30, fontSize: 12))),
                  if(isSettingPattern && enteredPattern.length>=4) ElevatedButton(onPressed: ()=> savePattern(enteredPattern), style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF00E676), foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))), child: Text("Save Pattern", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                ]),
              ])),
            ),
            Positioned(bottom: 25, left: 0, right: 0, child: Column(children: [
                GestureDetector(onTap: tryFingerprint, child: Container(width: 120, height: 120, color: Colors.transparent, child: Center(child: Icon(Icons.touch_app, color: Colors.white12, size: 20)))),
                GestureDetector(onTap: tryFingerprint, child: Container(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6), decoration: BoxDecoration(color: Color(0xFF1A1F2E), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white12)), child: Text("खालच्या Original Sensor ला Touch करा 👇", style: TextStyle(color: Colors.white60, fontSize: 10)))),
              ]),
            ),
          ]),
        ),
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
    double cellW = size.width/3; double cellH = size.height/3; List<Offset> points = [];
    for(int idx in enteredPattern){ int row = idx ~/ 3; int col = idx % 3; points.add(Offset(col*cellW + cellW/2, row*cellH + cellH/2)); }
    for(int i=0;i<points.length-1;i++){ canvas.drawLine(points[i], points[i+1], linePaint); }
    if(fingerPos!=null && points.isNotEmpty){ canvas.drawLine(points.last, fingerPos!, linePaint); }
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
}class DainikKharchApp extends StatefulWidget { @override State<DainikKharchApp> createState()=>_DState(); }
class _DState extends State<DainikKharchApp> {
  List<Expense> exps = []; List<Udhaari> udhars = []; DateTime selDate = DateTime.now(); int tab = 0; double monthlyBudget = 4000;
  List<Map<String, dynamic>> catBlocks = [
    {"title":"भाजीपाला","icon":"🥬","cat":"भाजीपाला","c1":0xFF00C853,"c2":0xFF69F0AE},
    {"title":"किराणा","icon":"🛒","cat":"किराणा","c1":0xFFD500F9,"c2":0xFFEA80FC},
    {"title":"पेट्रोल","icon":"⛽","cat":"प्रवास","c1":0xFF2962FF,"c2":0xFF82B1FF},
    {"title":"लाईट बिल","icon":"💡","cat":"बिल","c1":0xFFFF6D00,"c2":0xFFFFAB40},
    {"title":"रिचार्ज","icon":"📱","cat":"रिचार्ज","c1":0xFF00B8D4,"c2":0xFF84FFFF},
    {"title":"चहा नाश्ता","icon":"☕","cat":"खाद्य","c1":0xFFFF1744,"c2":0xFFFF8A80},
    {"title":"इतर","icon":"➕","cat":"इतर","c1":0xFF6C757D,"c2":0xFFADB5BD},
    // --- नवीन 3 ला बाकीच्या सारखे रंगीत केले ---
    {"title":"ई एम आय","icon":"🏦","बँक":"emi","c1":0xFF4527A0,"c2":0xFF7E57C2},
    {"title":"इन्शुरन्स","icon":"🛡️","cat":"बँक","c1":0xFF00695C,"c2":0xFF26A69A},
    {"title":"दूध","icon":"🥛","cat":"किराणा","c1":0xFFEF6C00,"c2":0xFFFFCC80},
  ];
  @override void initState(){ super.initState(); load(); }
  Future<void> load() async { final p = await SharedPreferences.getInstance(); var s = p.getString('ex'); if(s!=null) exps = (jsonDecode(s) as List).map((e)=>Expense.fromJson(e)).toList(); var u = p.getString('ud'); if(u!=null) udhars = (jsonDecode(u) as List).map((e)=>Udhaari.fromJson(e)).toList(); var b = p.getDouble('budget'); if(b!=null) monthlyBudget=b; var ln = p.getString('lang'); if(ln!=null) currentLang = ln; setState((){}); }
  Future<void> save() async { final p = await SharedPreferences.getInstance(); p.setString('ex', jsonEncode(exps.map((e)=>e.toJson()).toList())); p.setString('ud', jsonEncode(udhars.map((e)=>e.toJson()).toList())); p.setDouble('budget', monthlyBudget); }
  Future<void> backupData() async {
    try {
      Map<String, dynamic> allData = {'expenses': exps.map((e)=>e.toJson()).toList(), 'udhaari': udhars.map((e)=>e.toJson()).toList(), 'budget': monthlyBudget};
      String jsonStr = jsonEncode(allData);
      String? dir = await FilePicker.platform.getDirectoryPath();
      if(dir!= null){
        final file = File('$dir/kharch_backup_${DateFormat('dd-MMM-yy').format(DateTime.now())}.json');
        await file.writeAsString(jsonStr);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Backup झाला: ${file.path}"), backgroundColor: Color(0xFF00E676)));
      }
    } catch(e){ ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"))); }
  }
  Future<void> restoreData() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['json']);
      if(result!= null){
        String content = await File(result.files.single.path!).readAsString();
        Map<String, dynamic> data = jsonDecode(content);
        setState((){
          exps = (data['expenses'] as List).map((e)=>Expense.fromJson(e)).toList();
          if(data['udhaari']!= null) udhars = (data['udhaari'] as List).map((e)=>Udhaari.fromJson(e)).toList();
          if(data['budget']!= null) monthlyBudget = (data['budget'] as num).toDouble();
        });
        save();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Restore झाला!"), backgroundColor: Color(0xFF00E676)));
      }
    } catch(e){ ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"))); }
  }
  bool sameDay(DateTime a,b) => a.year==b.year && a.month==b.month && a.day==b.day;
  void addExp(String t,String a,String c){ setState(()=> exps.insert(0, Expense(title:t, amount:a, cat:c, date:selDate))); save(); }
  void editBudgetDialog(){
    TextEditingController bCtrl = TextEditingController(text: monthlyBudget.toInt().toString());
    showDialog(context: context, builder: (ctx)=> AlertDialog(backgroundColor: Color(0xFF1E2635), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), title: Text("बजेट टाका", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)), content: TextField(controller: bCtrl, keyboardType: TextInputType.number, autofocus: true, style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold), decoration: InputDecoration(prefixText: "₹ ", filled: true, fillColor: Colors.white10, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))), actions: [TextButton(onPressed: ()=>Navigator.pop(ctx), child: Text("रद्द")), ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF00E676)), onPressed: (){ if(bCtrl.text.isNotEmpty){ setState(()=> monthlyBudget = double.tryParse(bCtrl.text)??4000); save(); Navigator.pop(ctx); } }, child: Text("Save", style: TextStyle(color: Colors.black)))],));
  }
  void showListOptions(int index, Expense e){
    TextEditingController tCtrl = TextEditingController(text: e.title); TextEditingController aCtrl = TextEditingController(text: e.amount);
    showModalBottomSheet(context: context, backgroundColor: Color(0xFF12151E), shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))), builder: (ctx)=> Padding(padding: EdgeInsets.all(20), child: Column(mainAxisSize: MainAxisSize.min, children: [Text("एडिट / डिलीट", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)), SizedBox(height: 14), TextField(controller: tCtrl, style: TextStyle(color: Colors.white), decoration: InputDecoration(labelText: "नाव", filled: true, fillColor: Colors.white10, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))), SizedBox(height: 10), TextField(controller: aCtrl, keyboardType: TextInputType.number, style: TextStyle(color: Colors.white), decoration: InputDecoration(labelText: "रक्कम", filled: true, fillColor: Colors.white10, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))), SizedBox(height: 16), Row(children: [Expanded(child: ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent), icon: Icon(Icons.delete), label: Text("डिलीट"), onPressed: (){ setState(()=> exps.removeAt(index)); save(); Navigator.pop(ctx); })), SizedBox(width: 10), Expanded(child: ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF00E676)), icon: Icon(Icons.save), label: Text("अपडेट"), onPressed: (){ setState(()=> exps[index] = Expense(title: tCtrl.text, amount: aCtrl.text, cat: e.cat, date: e.date)); save(); Navigator.pop(ctx); })),]),])));
  }
  void openManualEntry(Map<String, dynamic> block){
    TextEditingController amtCtrl = TextEditingController(); TextEditingController noteCtrl = TextEditingController(text: block['title']);
    showDialog(context: context, builder: (ctx)=> Dialog(backgroundColor: Colors.transparent, child: Container(padding: EdgeInsets.all(20), decoration: BoxDecoration(color: Color(0xFF1E2635), borderRadius: BorderRadius.circular(24)), child: Column(mainAxisSize: MainAxisSize.min, children: [Text("${block['title']} खर्च", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)), SizedBox(height: 14), TextField(controller: amtCtrl, keyboardType: TextInputType.number, autofocus: true, style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900), decoration: InputDecoration(prefixText: "₹ ", filled: true, fillColor: Colors.white10, border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none))), SizedBox(height: 10), TextField(controller: noteCtrl, style: TextStyle(color: Colors.white), decoration: InputDecoration(labelText: "तपशील", filled: true, fillColor: Colors.white10, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))), SizedBox(height: 14), ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Color(block['c1'])), onPressed: (){ if(amtCtrl.text.isNotEmpty){ addExp(noteCtrl.text.isEmpty? block['title'] : noteCtrl.text, amtCtrl.text, block['cat']); Navigator.pop(ctx); } }, child: Text("Add करा"))]))));
  }
  @override Widget build(BuildContext context){
    return Scaffold(
      backgroundColor: Color(0xFF070A11),
      body: warliBackground(child: tab==0? buildDash() : tab==1? buildLedger() : tab==2? buildUdhaari() : buildSettingsPage()),
      bottomNavigationBar: Container(margin: EdgeInsets.all(14), padding: EdgeInsets.all(6), decoration: BoxDecoration(color: Color(0xFF12151E), borderRadius: BorderRadius.circular(28), border: Border.all(color: Colors.white10)), child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [nav(Icons.dashboard_rounded,0), nav(Icons.receipt_long_rounded,1), nav(Icons.handshake_rounded,2), nav(Icons.settings_rounded,3)])),
    );
  }
  Widget nav(IconData ic,int idx){ bool s=tab==idx; return GestureDetector(onTap: ()=>setState(()=>tab=idx), child: AnimatedContainer(duration: Duration(milliseconds: 250), padding: EdgeInsets.symmetric(horizontal: 22, vertical: 12), decoration: BoxDecoration(color: s?Color(0xFF00E676):Colors.transparent, borderRadius: BorderRadius.circular(20)), child: Icon(ic, color: s?Colors.black:Colors.white38, size: 22))); }

  Widget buildDash(){
    double today=0; for(var e in exps){ if(sameDay(e.date, selDate)) today+= double.tryParse(e.amount)??0; }
    double perc = (today/monthlyBudget).clamp(0,1); double remaining = monthlyBudget - today;
    var todaysList = exps.where((e)=>sameDay(e.date, selDate)).toList();
    var L = appLang[currentLang]!;
    return SingleChildScrollView(
      child: Padding(padding: EdgeInsets.fromLTRB(16,40,16,100), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(padding: EdgeInsets.symmetric(horizontal: 18, vertical: 14), decoration: BoxDecoration(gradient: LinearGradient(colors: [Color(0xFFD4FF5A), Color(0xFF8BC34A)]), borderRadius: BorderRadius.circular(20)), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(L['dash']!, style: GoogleFonts.poppins(fontWeight: FontWeight.w800, fontSize: 15, color: Colors.black)), Icon(Icons.logout, size: 20)])),
        SizedBox(height: 16),
        Container(padding: EdgeInsets.all(18), decoration: BoxDecoration(color: Color(0xFF12151E), borderRadius: BorderRadius.circular(22), border: Border.all(color: Colors.white10)), child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(L['today']!, style: TextStyle(color: Colors.white54, fontSize: 12)), SizedBox(height: 4), Text("₹${today.toInt()}", style: TextStyle(color: Color(0xFFFF3B30), fontSize: 24, fontWeight: FontWeight.w900))]),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [Text(L['urle']!, style: TextStyle(color: Colors.white70, fontSize: 13)), Text("₹${remaining.toInt()}", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900))]),
          ]),
          SizedBox(height: 14),
          ClipRRect(borderRadius: BorderRadius.circular(10), child: LinearProgressIndicator(value: perc, minHeight: 8, backgroundColor: Colors.white12, valueColor: AlwaysStoppedAnimation<Color>(perc>0.9? Colors.redAccent : Color(0xFF00E676)))),
          SizedBox(height: 14),
          GestureDetector(onTap: editBudgetDialog, child: Container(padding: EdgeInsets.symmetric(horizontal: 22, vertical: 9), decoration: BoxDecoration(color: Color(0xFFB5FF00), borderRadius: BorderRadius.circular(30), boxShadow: [BoxShadow(color: Color(0xFFB5FF00).withOpacity(0.6), blurRadius: 12)]), child: Text("${L['budget']!} ₹${monthlyBudget.toInt()}", style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 14)))),
        ])),
        SizedBox(height: 18),
        GridView.builder(shrinkWrap: true, physics: NeverScrollableScrollPhysics(), gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 0.95), itemCount: catBlocks.length, itemBuilder: (c,i){
          var b = catBlocks[i];
          return GestureDetector(onTap: ()=>openManualEntry(b), child: Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(b['c1']), Color(b['c2'])]), borderRadius: BorderRadius.circular(22)), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Text(b['icon'], style: TextStyle(fontSize: 30)), SizedBox(height: 6), Text(b['title'], style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),])));
        }),
        SizedBox(height: 22),
        Text("${L['list']!} (${todaysList.length})", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        SizedBox(height: 10),
     ...todaysList.asMap().entries.map((entry){
          int idx = exps.indexOf(entry.value); var e = entry.value;
          String dateStr = DateFormat('dd MMM').format(e.date);
          return GestureDetector(
            onTap: ()=>showListOptions(idx, e),
            child: Container(margin: EdgeInsets.only(bottom: 10), padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12), decoration: BoxDecoration(color: Color(0xFF12151E), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withOpacity(0.06))),
              child: Row(children: [
                Container(width: 44, height: 44, decoration: BoxDecoration(color: Colors.white.withOpacity(0.08), shape: BoxShape.circle), child: Icon(Icons.arrow_outward_rounded, color: Colors.white, size: 20)),
                SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text("Paid to", style: TextStyle(color: Colors.white54, fontSize: 11)),
                  Text(e.title, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                  SizedBox(height: 2),
                  Row(children: [Icon(Icons.calendar_today_rounded, size: 11, color: Colors.white38), SizedBox(width: 4), Text(dateStr, style: TextStyle(color: Colors.white38, fontSize: 12)), SizedBox(width: 8), Container(padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(6)), child: Text(e.cat, style: TextStyle(color: Colors.white60, fontSize: 10)))]),
                ])),
                Text("₹${e.amount}", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
              ]),
            ),
          );
        }).toList(),
        if(todaysList.isEmpty) Padding(padding: EdgeInsets.only(top: 20), child: Center(child: Text(appLang[currentLang]!['noExp']!, style: TextStyle(color: Colors.white30)))),
      ])),
    );
  }
  Widget buildLedger(){
    return Padding(padding: EdgeInsets.fromLTRB(16,60,16,100), child: Column(children: [Text("सर्व खर्च", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)), Expanded(child: ListView.builder(itemCount: exps.length, itemBuilder: (c,i){ var e=exps[i]; String dStr = DateFormat('dd MMM, yy').format(e.date); return ListTile(title: Text(e.title, style: TextStyle(color: Colors.white)), subtitle: Text("$dStr • ${e.cat}", style: TextStyle(color: Colors.white54)), trailing: Text("₹${e.amount}", style: TextStyle(color: Colors.white))); }))]));
  }
  Widget buildUdhaari(){ return Center(child: Text("उधारी", style: TextStyle(color: Colors.white))); }
  Widget buildSettingsPage(){
    var L = appLang[currentLang]!;
    return Padding(padding: EdgeInsets.fromLTRB(16,60,16,100), child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(L['setting']!, style: GoogleFonts.poppins(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
      SizedBox(height: 20),
      Container(padding: EdgeInsets.all(18), decoration: BoxDecoration(color: Color(0xFF12151E), borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.white10)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Icon(Icons.language, color: Color(0xFF00E676)), SizedBox(width: 10), Text(L['lang']!, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))]),
        SizedBox(height: 14),
        Row(children: [langBtn('मराठी','mr'), SizedBox(width:10), langBtn('हिंदी','hi'), SizedBox(width:10), langBtn('English','en')])
      ])),
      SizedBox(height: 16),
      Container(decoration: BoxDecoration(color: Color(0xFF12151E), borderRadius: BorderRadius.circular(18)), child: Column(children: [
        ListTile(leading: Container(padding: EdgeInsets.all(8), decoration: BoxDecoration(color: Color(0xFF00E676).withOpacity(0.2), borderRadius: BorderRadius.circular(10)), child: Icon(Icons.backup_rounded, color: Color(0xFF00E676))), title: Text(L['backup']!, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)), subtitle: Text("Download folder मध्ये save होईल", style: TextStyle(color: Colors.white38, fontSize: 11)), trailing: Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white30), onTap: backupData),
        Divider(color: Colors.white10, height: 1),
        ListTile(leading: Container(padding: EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.orange.withOpacity(0.2), borderRadius: BorderRadius.circular(10)), child: Icon(Icons.restore_rounded, color: Colors.orangeAccent)), title: Text(L['restore']!, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)), subtitle: Text("जुनी json file निवडा", style: TextStyle(color: Colors.white38, fontSize: 11)), trailing: Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white30), onTap: restoreData),
      ])),
      SizedBox(height: 20),
      Center(child: Text("Version 2.0 • Premium", style: TextStyle(color: Colors.white24, fontSize: 11))),
    ])));
  }
  Widget langBtn(String title, String code){
    bool sel = currentLang == code;
    return GestureDetector(onTap: () async { setState(()=> currentLang = code); final p = await SharedPreferences.getInstance(); p.setString('lang', code); }, child: AnimatedContainer(duration: Duration(milliseconds: 200), padding: EdgeInsets.symmetric(horizontal: 16, vertical: 9), decoration: BoxDecoration(color: sel? Color(0xFF00E676): Colors.white.withOpacity(0.08), borderRadius: BorderRadius.circular(20), border: Border.all(color: sel? Color(0xFF00E676): Colors.white12)), child: Text(title, style: TextStyle(color: sel? Colors.black: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))));
  }
}
