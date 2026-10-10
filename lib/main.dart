import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(MaterialApp(debugShowCheckedModeBanner: false, home: DainikKharchApp()));

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

class _DState extends State<DainikKharchApp> with SingleTickerProviderStateMixin {
  List<Expense> exps = []; List<Udhaari> udhars = [];
  DateTime selDate = DateTime.now(); int tab = 0;
  double monthlyBudget = 20000;
  late AnimationController pulseCtrl;

  // PREMIUM 3D BLOCKS - DIFFERENT GRADIENT COLORS
  List<Map<String, dynamic>> catBlocks = [
    {"title":"भाजीपाला","icon":"🥬","cat":"भाजीपाला","c1":0xFF00C853,"c2":0xFF69F0AE,"shadow":0xFF00C853},
    {"title":"किराणा","icon":"🛒","cat":"किराणा","c1":0xFFD500F9,"c2":0xFFEA80FC,"shadow":0xFFAA00FF},
    {"title":"पेट्रोल","icon":"⛽","cat":"प्रवास","c1":0xFF2962FF,"c2":0xFF82B1FF,"shadow":0xFF2962FF},
    {"title":"लाईट बिल","icon":"💡","cat":"बिल","c1":0xFFFF6D00,"c2":0xFFFFAB40,"shadow":0xFFFF6D00},
    {"title":"रिचार्ज","icon":"📱","cat":"रिचार्ज","c1":0xFF00B8D4,"c2":0xFF84FFFF,"shadow":0xFF00B8D4},
    {"title":"चहा नाश्ता","icon":"☕","cat":"खाद्य","c1":0xFFFF1744,"c2":0xFFFF8A80,"shadow":0xFFFF1744},
  ];

  @override void initState(){ super.initState(); load(); pulseCtrl = AnimationController(vsync: this, duration: Duration(milliseconds: 800))..repeat(reverse: true); }
  Future<void> load() async { final p = await SharedPreferences.getInstance(); var s = p.getString('ex'); if(s!=null) exps = (jsonDecode(s) as List).map((e)=>Expense.fromJson(e)).toList(); var u = p.getString('ud'); if(u!=null) udhars = (jsonDecode(u) as List).map((e)=>Udhaari.fromJson(e)).toList(); var b = p.getDouble('budget'); if(b!=null) monthlyBudget=b; setState((){}); }
  Future<void> save() async { final p = await SharedPreferences.getInstance(); p.setString('ex', jsonEncode(exps.map((e)=>e.toJson()).toList())); p.setString('ud', jsonEncode(udhars.map((e)=>e.toJson()).toList())); p.setDouble('budget', monthlyBudget); }
  bool sameDay(DateTime a,b) => a.year==b.year && a.month==b.month && a.day==b.day;
  void addExp(String t,String a,String c){ setState(()=> exps.insert(0, Expense(title:t, amount:a, cat:c, date:selDate))); save(); }

  void openManualEntry(Map<String, dynamic> block){
    TextEditingController amtCtrl = TextEditingController();
    TextEditingController noteCtrl = TextEditingController(text: block['title']);
    showDialog(context: context, builder: (ctx)=> Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF1E2635), Color(0xFF0B0E14)]), borderRadius: BorderRadius.circular(24), border: Border.all(color: Color(block['c1']).withOpacity(0.5), width: 1.5), boxShadow: [BoxShadow(color: Color(block['shadow']).withOpacity(0.3), blurRadius: 30)]),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Row(children: [Container(padding: EdgeInsets.all(10), decoration: BoxDecoration(gradient: LinearGradient(colors: [Color(block['c1']), Color(block['c2'])]), borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Color(block['shadow']).withOpacity(0.5), blurRadius: 12)]), child: Text(block['icon'], style: TextStyle(fontSize: 24))), SizedBox(width: 12), Expanded(child: Text("${block['title']}\nखर्च टाका", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)))]),
          SizedBox(height: 18),
          TextField(controller: amtCtrl, keyboardType: TextInputType.number, autofocus: true, style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900), decoration: InputDecoration(prefixText: "₹ ", prefixStyle: TextStyle(color: Color(0xFF00E676), fontSize: 28, fontWeight: FontWeight.bold), hintText: "120", hintStyle: TextStyle(color: Colors.white24), filled: true, fillColor: Colors.white.withOpacity(0.07), border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none))),
          SizedBox(height: 12),
          TextField(controller: noteCtrl, style: TextStyle(color: Colors.white), decoration: InputDecoration(labelText: "तपशील", labelStyle: TextStyle(color: Colors.white54, fontSize: 12), filled: true, fillColor: Colors.white.withOpacity(0.07), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
          SizedBox(height: 18),
          Row(children: [Expanded(child: TextButton(onPressed: ()=> Navigator.pop(ctx), child: Text("रद्द", style: TextStyle(color: Colors.white54)))), SizedBox(width: 10), Expanded(flex: 2, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Color(block['c1']), foregroundColor: Colors.white, padding: EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 10, shadowColor: Color(block['shadow'])), onPressed: (){ if(amtCtrl.text.isNotEmpty){ addExp(noteCtrl.text.isEmpty? block['title'] : noteCtrl.text, amtCtrl.text, block['cat']); Navigator.pop(ctx); } }, child: Text("OK - Add करा", style: TextStyle(fontWeight: FontWeight.bold)) ))])
        ]),
      ),
    ));
  }

  @override Widget build(BuildContext context){
    return Scaffold(
      backgroundColor: Color(0xFF0B0E14),
      floatingActionButton: tab==0? FloatingActionButton(onPressed: showVoiceDialog, backgroundColor: Color(0xFF00E676), child: Icon(Icons.mic, color: Colors.black)):null,
      body: tab==0? buildDash() : tab==1? buildLedger() : tab==2? buildUdhaari() : buildChart(),
      bottomNavigationBar: Container(margin: EdgeInsets.all(14), padding: EdgeInsets.all(6), decoration: BoxDecoration(color: Color(0xFF1A1F2B), borderRadius: BorderRadius.circular(28)), child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [nav(Icons.dashboard,0), nav(Icons.receipt_long,1), nav(Icons.handshake,2), nav(Icons.bar_chart,3)])),
    );
  }
  Widget nav(IconData ic,int idx){ bool s=tab==idx; return GestureDetector(onTap: ()=>setState(()=>tab=idx), child: AnimatedContainer(duration: Duration(milliseconds: 200), padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12), decoration: BoxDecoration(color: s?Color(0xFF00E676):Colors.transparent, borderRadius: BorderRadius.circular(20), boxShadow: s?[BoxShadow(color: Color(0xFF00E676).withOpacity(0.4), blurRadius: 10)]:[]), child: Icon(ic, color: s?Colors.black:Colors.white54))); }

  Widget buildDash(){
    double today=0; for(var e in exps){ if(sameDay(e.date, selDate)) today+= double.tryParse(e.amount)??0; }
    double perc = (today/monthlyBudget).clamp(0,1);
    double remaining = monthlyBudget - today;

    return CustomScrollView(slivers: [
      SliverAppBar(expandedHeight: 390, pinned: true, backgroundColor: Color(0xFF0B0E14), flexibleSpace: FlexibleSpaceBar(background: Stack(children: [
        Positioned(left: 16,right: 16,top: 55, child: Container(padding: EdgeInsets.all(16), decoration: BoxDecoration(gradient: LinearGradient(colors: [Color(0xFFD4FF5A), Color(0xFF8BC34A)]), borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Color(0xFFD4FF5A).withOpacity(0.3), blurRadius: 20, offset: Offset(0,10))]), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text("दैनिक खर्च - PREMIUM 3D", style: GoogleFonts.poppins(fontWeight: FontWeight.w900, fontSize: 19, color: Colors.black)),
          Text("6 Premium Blocks • Tap to Add", style: TextStyle(fontSize: 11, color: Colors.black87, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Row(children: [Expanded(child: ElevatedButton.icon(onPressed: showVoiceDialog, icon: Icon(Icons.mic, size: 14), label: Text("बोला", style: TextStyle(fontSize: 10)), style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Color(0xFFD4FF5A)))), SizedBox(width: 6), Expanded(child: ElevatedButton.icon(onPressed: showSMSDialog, icon: Icon(Icons.sms, size: 14), label: Text("SMS पेस्ट", style: TextStyle(fontSize: 10)), style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black)))])
        ]))),
        Positioned(left: 16,right: 16,bottom: 10, child: Container(padding: EdgeInsets.all(14), decoration: BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF1A1F2B), Color(0xFF151A25)]), borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.white.withOpacity(0.08)), boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 15)]), child: Column(children: [
          Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text("आजचा खर्च", style: TextStyle(color: Colors.white54, fontSize: 11)), Text("₹${today.toInt()}", style: GoogleFonts.poppins(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 20))])), Container(width: 1, height: 40, color: Colors.white10), Expanded(child: Padding(padding: EdgeInsets.only(left: 12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text("शिल्लक राहिले", style: TextStyle(color: Colors.white54, fontSize: 11)), Text("₹${remaining.toInt()}", style: GoogleFonts.poppins(color: Color(0xFF00E676), fontWeight: FontWeight.bold, fontSize: 20))]))),]),
          SizedBox(height: 10), ClipRRect(borderRadius: BorderRadius.circular(10), child: LinearProgressIndicator(value: perc, minHeight: 8, backgroundColor: Colors.white10, valueColor: AlwaysStoppedAnimation(perc>0.8? Colors.redAccent : Color(0xFF00E676)))), SizedBox(height: 6), Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text("खर्च झाले: ₹${today.toInt()}", style: TextStyle(color: Colors.white38, fontSize: 10)), Text("बजेट: ₹${monthlyBudget.toInt()}", style: TextStyle(color: Colors.white38, fontSize: 10))]),
        ]))),
      ]))),
      SliverToBoxAdapter(child: Padding(padding: EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Text("Premium 3D Blocks", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)), Spacer(), Container(padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Color(0xFF00E676).withOpacity(0.15), borderRadius: BorderRadius.circular(20)), child: Text("Tap + Hold = Edit", style: TextStyle(color: Color(0xFF00E676), fontSize: 9)))]),
        SizedBox(height: 14),
        GridView.builder(
          shrinkWrap: true, physics: NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, childAspectRatio: 0.95, crossAxisSpacing: 12, mainAxisSpacing: 12),
          itemCount: catBlocks.length,
          itemBuilder: (c,i){
            var q = catBlocks[i];
            return GestureDetector(
              onTap: ()=> openManualEntry(q),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(q['c1']), Color(q['c2'])]),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [BoxShadow(color: Color(q['shadow']).withOpacity(0.45), blurRadius: 18, offset: Offset(0,10)), BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 8, offset: Offset(0,4))],
                  border: Border.all(color: Colors.white.withOpacity(0.25), width: 1),
                ),
                child: Stack(children: [
                  // Top glossy highlight
                  Positioned(top: 0, left: 0, right: 0, child: Container(height: 40, decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.white.withOpacity(0.35), Colors.transparent]), borderRadius: BorderRadius.vertical(top: Radius.circular(22))))),
                  // Big icon background
                  Positioned(right: -10, bottom: -10, child: Text(q['icon'].toString(), style: TextStyle(fontSize: 60, color: Colors.black.withOpacity(0.12)))),
                  Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Container(padding: EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.black.withOpacity(0.15), shape: BoxShape.circle, border: Border.all(color: Colors.white.withOpacity(0.3))), child: Text(q['icon'].toString(), style: TextStyle(fontSize: 26))),
                    SizedBox(height: 10),
                    Text(q['title'].toString(), style: GoogleFonts.poppins(fontWeight: FontWeight.w900, fontSize: 12, color: Colors.white, shadows: [Shadow(color: Colors.black26, blurRadius: 4)]), textAlign: TextAlign.center),
                    SizedBox(height: 6),
                    Container(padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: Colors.black.withOpacity(0.85), borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)]), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.touch_app, size: 10, color: Color(0xFF00E676)), SizedBox(width: 3), Text("ADD", style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5))])),
                  ])),
                ]),
              ),
            );
          },
        ),
        SizedBox(height: 22),
        Row(children: [Text("आजच्या नोंदी", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), Spacer(), Text("${exps.where((e)=>sameDay(e.date, selDate)).length} नोंदी", style: TextStyle(color: Colors.white38, fontSize: 11))]),
        SizedBox(height: 8),
        ...exps.where((e)=>sameDay(e.date, selDate)).map((e)=> tile(e.title, "₹${e.amount}", e.cat, e.date)).toList(),
        if(exps.where((e)=>sameDay(e.date, selDate)).isEmpty) Container(padding: EdgeInsets.all(20), decoration: BoxDecoration(color: Color(0xFF1A1F2B), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white10)), child: Center(child: Text("वरच्या 3D Block वर टच करून खर्च टाका!", style: TextStyle(color: Colors.white38, fontSize: 12)))),
        SizedBox(height: 90),
      ])))
    ]);
  }

  Widget tile(String t,String a,String c, DateTime d){ return Container(margin: EdgeInsets.symmetric(vertical: 4), padding: EdgeInsets.all(12), decoration: BoxDecoration(color: Color(0xFF1A1F2B), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withOpacity(0.05))), child: Row(children: [Container(padding: EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(8)), child: Text(c[0], style: TextStyle(color: Colors.white))), SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(t, style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)), Text("$c • ${DateFormat('hh:mm a').format(d)}", style: TextStyle(color: Colors.white38, fontSize: 10))])), Text(a, style: TextStyle(color: Color(0xFF00E676), fontWeight: FontWeight.bold))])); }

  void showVoiceDialog(){ String txt=""; showDialog(context: context, builder: (c)=> AlertDialog(backgroundColor: Color(0xFF1A1F2B), title: Row(children: [ScaleTransition(scale: Tween(begin: 1.0, end: 1.3).animate(pulseCtrl), child: Icon(Icons.mic, color: Colors.red)), SizedBox(width: 8), Text("बोला...", style: TextStyle(color: Colors.white))]), content: Column(mainAxisSize: MainAxisSize.min, children: [Text("उदा: ३०० रुपये भाजीपाला", style: TextStyle(color: Colors.white54, fontSize: 11)), TextField(decoration: InputDecoration(hintText: "300 kirana", hintStyle: TextStyle(color: Colors.white24)), style: TextStyle(color: Colors.white), onChanged: (v)=>txt=v)]), actions: [TextButton(onPressed: ()=>Navigator.pop(c), child: Text("रद्द")), ElevatedButton(onPressed: (){ RegExp r = RegExp(r'(\d+)'); var m=r.firstMatch(txt); if(m!=null){ addExp(txt, m.group(1)!, "खाद्य"); Navigator.pop(c); } }, child: Text("जतन करा"), style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF00E676)))],)); }
  void showSMSDialog(){ String sms=""; showDialog(context: context, builder: (c)=> AlertDialog(backgroundColor: Color(0xFF1A1F2B), title: Text("UPI SMS पेस्ट करा", style: TextStyle(color: Colors.white, fontSize: 16)), content: Column(mainAxisSize: MainAxisSize.min, children: [Text("Google Pay SMS कॉपी करा", style: TextStyle(color: Colors.white54, fontSize: 11)), SizedBox(height: 8), TextField(maxLines: 3, decoration: InputDecoration(hintText: "Rs. 100 paid to...", hintStyle: TextStyle(color: Colors.white24), border: OutlineInputBorder()), style: TextStyle(color: Colors.white, fontSize: 12), onChanged: (v)=>sms=v)]), actions: [ElevatedButton(onPressed: (){ RegExp reg = RegExp(r'(?:Rs\.?|INR)\s?(\d+)', caseSensitive: false); var mat=reg.firstMatch(sms); if(mat!=null){ String amt=mat.group(1)!; String shop="UPI दुकान"; if(sms.contains("to")) shop=sms.split("to").last.substring(0,15); addExp(shop, amt, "UPI"); Navigator.pop(c); } }, child: Text("Auto Detect"), style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF00E676), foregroundColor: Colors.black))]); }
  Widget buildUdhaari(){ double totalDen=0, totalGhet=0; for(var u in udhars){ if(u.type=="देणे") totalDen+= double.tryParse(u.amount)??0; else totalGhet+= double.tryParse(u.amount)??0; } return Scaffold(backgroundColor: Color(0xFF0B0E14), appBar: AppBar(backgroundColor: Color(0xFF0B0E14), title: Text("उधारी खाते", style: TextStyle(color: Colors.white)), actions: [IconButton(onPressed: showUdhaariAdd, icon: Icon(Icons.add, color: Color(0xFF00E676)))]), body: Column(children: [Padding(padding: EdgeInsets.all(16), child: Row(children: [stat("द्यायचे","₹${totalDen.toInt()}",Colors.red), SizedBox(width: 10), stat("यायचे","₹${totalGhet.toInt()}",Colors.green)])), Expanded(child: ListView(children: udhars.map((u)=> Container(margin: EdgeInsets.symmetric(horizontal: 16, vertical: 5), padding: EdgeInsets.all(12), decoration: BoxDecoration(color: Color(0xFF1A1F2B), borderRadius: BorderRadius.circular(14)), child: Row(children: [CircleAvatar(backgroundColor: u.type=="देणे"?Colors.red:Colors.green, child: Text(u.name.isNotEmpty?u.name[0]:"?")), SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(u.name, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), Text("${u.type} • ${DateFormat('dd MMM').format(u.date)}", style: TextStyle(color: Colors.white38, fontSize: 11))])), Text("₹${u.amount}", style: TextStyle(color: u.type=="देणे"?Colors.redAccent:Colors.greenAccent, fontWeight: FontWeight.bold)), IconButton(onPressed: (){ setState(()=> udhars.remove(u)); save(); }, icon: Icon(Icons.delete, color: Colors.white24, size: 18))]))).toList())),])); }
  void showUdhaariAdd(){ String name="", amt=""; String type="देणे"; showDialog(context: context, builder: (c)=> StatefulBuilder(builder: (c,setS)=> AlertDialog(backgroundColor: Color(0xFF1A1F2B), title: Text("उधारी नोंद", style: TextStyle(color: Colors.white)), content: Column(mainAxisSize: MainAxisSize.min, children: [Text
