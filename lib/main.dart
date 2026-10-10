import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(MaterialApp(debugShowCheckedModeBanner: false, home: DainikKharchApp()));

// Models
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
  PageController pgCtrl = PageController(viewportFraction: 0.88);
  late AnimationController pulseCtrl;

  // EDITABLE PRESETS - Color int madhe (Save honar)
  List<Map<String, dynamic>> presets = [
    {"title":"चहा नाश्ता","icon":"☕","cat":"खाद्य","amt":"30","c":0xFFFF9800},
    {"title":"भाजीपाला","icon":"🥬","cat":"किराणा","amt":"120","c":0xFF4CAF50},
    {"title":"पेट्रोल","icon":"⛽","cat":"प्रवास","amt":"100","c":0xFF2196F3},
    {"title":"टिफिन","icon":"🍱","cat":"खाद्य","amt":"80","c":0xFFFFC107},
    {"title":"किराणा","icon":"🛒","cat":"किराणा","amt":"500","c":0xFF9C27B0},
    {"title":"लाईट बिल","icon":"💡","cat":"बिल","amt":"300","c":0xFF009688},
  ];

  @override void initState(){ super.initState(); load(); loadPresets(); pulseCtrl = AnimationController(vsync: this, duration: Duration(milliseconds: 800))..repeat(reverse: true); }

  Future<void> load() async { final p = await SharedPreferences.getInstance(); var s = p.getString('ex'); if(s!=null) exps = (jsonDecode(s) as List).map((e)=>Expense.fromJson(e)).toList(); var u = p.getString('ud'); if(u!=null) udhars = (jsonDecode(u) as List).map((e)=>Udhaari.fromJson(e)).toList(); setState((){}); }
  Future<void> save() async { final p = await SharedPreferences.getInstance(); p.setString('ex', jsonEncode(exps.map((e)=>e.toJson()).toList())); p.setString('ud', jsonEncode(udhars.map((e)=>e.toJson()).toList())); }

  Future<void> savePresets() async { final p = await SharedPreferences.getInstance(); p.setString('presets', jsonEncode(presets)); }
  Future<void> loadPresets() async { final p = await SharedPreferences.getInstance(); var s = p.getString('presets'); if(s!=null){ setState(()=> presets = (jsonDecode(s) as List).map((e)=> Map<String,dynamic>.from(e)).toList()); } }

  bool sameDay(DateTime a,b) => a.year==b.year && a.month==b.month && a.day==b.day;
  void addExp(String t,String a,String c){ setState(()=> exps.insert(0, Expense(title:t, amount:a, cat:c, date:selDate))); save(); }
  void addUdhaar(String n,String a,String tp){ setState(()=> udhars.insert(0, Udhaari(name:n, amount:a, type:tp, date:DateTime.now()))); save(); }

  void editPresetDialog(int index){
    var q = presets[index];
    String tTitle = q['title'].toString(); String tAmt = q['amt'].toString(); String tCat = q['cat'].toString();
    TextEditingController c1 = TextEditingController(text: tTitle);
    TextEditingController c2 = TextEditingController(text: tAmt);
    TextEditingController c3 = TextEditingController(text: tCat);
    showDialog(context: context, builder: (ctx)=> AlertDialog(
      backgroundColor: Color(0xFF1A1F2B),
      title: Text("Edit करा ${q['icon']}", style: TextStyle(color: Colors.white, fontSize: 16)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: c1, style: TextStyle(color: Colors.white), decoration: InputDecoration(labelText: "नाव", labelStyle: TextStyle(color: Colors.white54))),
        SizedBox(height: 8),
        TextField(controller: c2, style: TextStyle(color: Colors.white), keyboardType: TextInputType.number, decoration: InputDecoration(labelText: "रक्कम ₹", labelStyle: TextStyle(color: Colors.white54))),
        SizedBox(height: 8),
        TextField(controller: c3, style: TextStyle(color: Colors.white), decoration: InputDecoration(labelText: "Category", labelStyle: TextStyle(color: Colors.white54))),
        SizedBox(height: 12),
        Text("Long Press karun edit karu shakto!", style: TextStyle(color: Colors.white24, fontSize: 10)),
      ]),
      actions: [
        TextButton(onPressed: ()=>Navigator.pop(ctx), child: Text("रद्द")),
        ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF00E676)), onPressed: (){
          setState((){
            presets[index]['title']=c1.text;
            presets[index]['amt']=c2.text;
            presets[index]['cat']=c3.text;
          });
          savePresets(); Navigator.pop(ctx);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("${c1.text} आता ₹${c2.text} झाला!")));
        }, child: Text("Save करा", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold))),
      ],
    ));
  }

  @override Widget build(BuildContext context){
    return Scaffold(
      backgroundColor: Color(0xFF0B0E14),
      floatingActionButton: tab==0? FloatingActionButton(onPressed: showVoiceDialog, backgroundColor: Color(0xFF00E676), child: Icon(Icons.mic, color: Colors.black)):null,
      body: tab==0? buildDash() : tab==1? buildLedger() : tab==2? buildUdhaari() : buildChart(),
      bottomNavigationBar: Container(margin: EdgeInsets.all(14), padding: EdgeInsets.all(6), decoration: BoxDecoration(color: Color(0xFF1A1F2B), borderRadius: BorderRadius.circular(28), boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 15)]), child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
        nav(Icons.dashboard,0), nav(Icons.receipt_long,1), nav(Icons.handshake,2), nav(Icons.bar_chart,3),
      ])),
    );
  }
  Widget nav(IconData ic,int idx){ bool s=tab==idx; return GestureDetector(onTap: ()=>setState(()=>tab=idx), child: AnimatedContainer(duration: Duration(milliseconds: 200), padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12), decoration: BoxDecoration(color: s?Color(0xFF00E676):Colors.transparent, borderRadius: BorderRadius.circular(20)), child: Icon(ic, color: s?Colors.black:Colors.white54))); }

  Widget buildDash(){
    double today=0; for(var e in exps){ if(sameDay(e.date, selDate)) today+= double.tryParse(e.amount)??0; }
    return CustomScrollView(slivers: [
      SliverAppBar(expandedHeight: 360, pinned: true, backgroundColor: Color(0xFF0B0E14), flexibleSpace: FlexibleSpaceBar(background: Stack(children: [
        Positioned(left: 16,right: 16,top: 60, child: Container(padding: EdgeInsets.all(16), decoration: BoxDecoration(gradient: LinearGradient(colors: [Color(0xFFD4FF5A), Color(0xFF8BC34A)]), borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Color(0xFFD4FF5A).withOpacity(0.3), blurRadius: 20, offset: Offset(0,10))]), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text("दैनिक खर्च - 3D PRO", style: GoogleFonts.poppins(fontWeight: FontWeight.w900, fontSize: 20)),
          Text("Voice + SMS + Udhari + Editable Table", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Row(children: [
            Expanded(child: ElevatedButton.icon(onPressed: showVoiceDialog, icon: Icon(Icons.mic, size: 14), label: Text("बोला", style: TextStyle(fontSize: 11)), style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Color(0xFFD4FF5A), padding: EdgeInsets.symmetric(horizontal: 8)))),
            SizedBox(width: 6),
            Expanded(child: ElevatedButton.icon(onPressed: showSMSDialog, icon: Icon(Icons.sms, size: 14), label: Text("SMS", style: TextStyle(fontSize: 11)), style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black, padding: EdgeInsets.symmetric(horizontal: 8)))),
            SizedBox(width: 6),
            Expanded(child: ElevatedButton.icon(onPressed: (){ ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Card la Long Press karun edit kara!"))); }, icon: Icon(Icons.edit, size: 14), label: Text("Edit Table", style: TextStyle(fontSize: 11)), style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF1A1F2B), foregroundColor: Colors.white, padding: EdgeInsets.symmetric(horizontal: 8)))),
          ])
        ]))),
        Positioned(left: 16,right: 16,bottom: 10, child: Row(children: [stat("आजचा खर्च","₹${today.toInt()}",Colors.redAccent), SizedBox(width:10), stat("शिल्लक","₹${(20000-today).toInt()}",Color(0xFF00E676))]))
      ]))),
      SliverToBoxAdapter(child: Padding(padding: EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Text("१-टॅप नोंद (Long Press = Edit)", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)), Spacer(), Icon(Icons.touch_app, color: Colors.white24, size: 16)]),
        SizedBox(height: 10),
        SizedBox(height: 150, child: PageView.builder(controller: pgCtrl, itemCount: presets.length, itemBuilder: (c,i){
          var q=presets[i];
          return GestureDetector(
            onTap: ()=>addExp(q['title'].toString(), q['amt'].toString(), q['cat'].toString()),
            onLongPress: ()=>editPresetDialog(i),
            child: Container(margin: EdgeInsets.all(8), decoration: BoxDecoration(color: Color(q['c']), borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Color(q['c']).withOpacity(0.4), blurRadius: 15, offset: Offset(0,8))]), child: Stack(children: [
              Positioned(right: 8, top: 8, child: Container(padding: EdgeInsets.all(4), decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(20)), child: Icon(Icons.edit, size: 12, color: Colors.white))),
              Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(q['icon'].toString(), style: TextStyle(fontSize: 34)),
                SizedBox(height: 4),
                Text(q['title'].toString(), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                SizedBox(height: 4),
                Container(padding: EdgeInsets.symmetric(horizontal: 10, vertical: 3), decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(12)), child: Text("₹${q['amt']}", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13)))
              ]))
            ])),
          );
        })),
        SizedBox(height: 12), Text("आजच्या नोंदी", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ...exps.where((e)=>sameDay(e.date, selDate)).map((e)=> tile(e.title, "₹${e.amount}", e.cat)).toList(),
        SizedBox(height: 90),
      ])))
    ]);
  }

  Widget stat(String t,String a,Color col){ return Expanded(child: Container(padding: EdgeInsets.all(12), decoration: BoxDecoration(color: Color(0xFF1A1F2B), borderRadius: BorderRadius.circular(16), border: Border.all(color: col.withOpacity(0.3))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(t, style: TextStyle(color: Colors.white54, fontSize: 10)), Text(a, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))]))); }
  Widget tile(String t,String a,String c){ return Container(margin: EdgeInsets.symmetric(vertical: 4), padding: EdgeInsets.all(12), decoration: BoxDecoration(color: Color(0xFF1A1F2B), borderRadius: BorderRadius.circular(12)), child: Row(children: [Expanded(child: Text(t, style: TextStyle(color: Colors.white, fontSize: 13))), Text(c, style: TextStyle(color: Colors.white38, fontSize: 10)), SizedBox(width: 10), Text(a, style: TextStyle(color: Color(0xFF00E676), fontWeight: FontWeight.bold))])); }

  void showVoiceDialog(){
    String txt=""; showDialog(context: context, builder: (c)=> AlertDialog(backgroundColor: Color(0xFF1A1F2B), title: Row(children: [ScaleTransition(scale: Tween(begin: 1.0, end: 1.3).animate(pulseCtrl), child: Icon(Icons.mic, color: Colors.red)), SizedBox(width: 8), Text("बोला...", style: TextStyle(color: Colors.white))]), content: Column(mainAxisSize: MainAxisSize.min, children: [
      Text("उदा: ३०० रुपये भाजीपाला", style: TextStyle(color: Colors.white54, fontSize: 11)),
      TextField(decoration: InputDecoration(hintText: "इथे टाइप करा - 300 kirana", hintStyle: TextStyle(color: Colors.white24)), style: TextStyle(color: Colors.white), onChanged: (v)=>txt=v),
    ]), actions: [TextButton(onPressed: ()=>Navigator.pop(c), child: Text("रद्द")), ElevatedButton(onPressed: (){ RegExp r = RegExp(r'(\d+)'); var m=r.firstMatch(txt); if(m!=null){ String amt=m.group(1)!; addExp(txt, amt, "खाद्य"); Navigator.pop(c); } }, child: Text("जतन करा"), style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF00E676)))],));
  }
  void showSMSDialog(){
    String sms=""; showDialog(context: context, builder: (c)=> AlertDialog(backgroundColor: Color(0xFF1A1F2B), title: Text("UPI SMS पेस्ट करा", style: TextStyle(color: Colors.white, fontSize: 16)), content: Column(mainAxisSize: MainAxisSize.min, children: [
      Text("Google Pay / PhonePe SMS कॉपी करा", style: TextStyle(color: Colors.white54, fontSize: 11)), SizedBox(height: 8),
      TextField(maxLines: 3, decoration: InputDecoration(hintText: "Rs. 100 paid to...", hintStyle: TextStyle(color: Colors.white24), border: OutlineInputBorder()), style: TextStyle(color: Colors.white, fontSize: 12), onChanged: (v)=>sms=v),
    ]), actions: [ElevatedButton(onPressed: (){ RegExp reg = RegExp(r'(?:Rs\.?|INR)\s?(\d+)', caseSensitive: false); var mat=reg.firstMatch(sms); if(mat!=null){ String amt=mat.group(1)!; String shop="UPI दुकान"; if(sms.contains("to")) shop=sms.split("to").last.substring(0,15); addExp(shop, amt, "UPI"); Navigator.pop(c); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("₹$amt Auto Add!"))); } }, child: Text("Auto Detect"), style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF00E676), foregroundColor: Colors.black))]));
  }
  Widget buildUdhaari(){
    double totalDen=0, totalGhet=0; for(var u in udhars){ if(u.type=="देणे") totalDen+= double.tryParse(u.amount)??0; else totalGhet+= double.tryParse(u.amount)??0; }
    return Scaffold(backgroundColor: Color(0xFF0B0E14), appBar: AppBar(backgroundColor: Color(0xFF0B0E14), title: Text("उधारी खाते", style: TextStyle(color: Colors.white)), actions: [IconButton(onPressed: showUdhaariAdd, icon: Icon(Icons.add, color: Color(0xFF00E676)))]), body: Column(children: [
      Padding(padding: EdgeInsets.all(16), child: Row(children: [stat("द्यायचे","₹${totalDen.toInt()}",Colors.red), SizedBox(width: 10), stat("यायचे","₹${totalGhet.toInt()}",Colors.green)])),
      Expanded(child: ListView(children: udhars.map((u)=> Container(margin: EdgeInsets.symmetric(horizontal: 16, vertical: 5), padding: EdgeInsets.all(12), decoration: BoxDecoration(color: Color(0xFF1A1F2B), borderRadius: BorderRadius.circular(14), border: Border.all(color: u.type=="देणे"?Colors.red.withOpacity(0.3):Colors.green.withOpacity(0.3))), child: Row(children: [CircleAvatar(backgroundColor: u.type=="देणे"?Colors.red:Colors.green, child: Text(u.name.isNotEmpty?u.name[0]:"?", style: TextStyle(color: Colors.white))), SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(u.name, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), Text("${u.type} • ${DateFormat('dd MMM').format(u.date)}", style: TextStyle(color: Colors.white38, fontSize: 11))])), Text("₹${u.amount}", style: TextStyle(color: u.type=="देणे"?Colors.redAccent:Colors.greenAccent, fontWeight: FontWeight.bold)), IconButton(onPressed: (){ setState(()=> udhars.remove(u)); save(); }, icon: Icon(Icons.delete, color: Colors.white24, size: 18))]))).toList())),
    ]));
  }
  void showUdhaariAdd(){
    String name="", amt=""; String type="देणे";
    showDialog(context: context, builder: (c)=> StatefulBuilder(builder: (c,setS)=> AlertDialog(backgroundColor: Color(0xFF1A1F2B), title: Text("उधारी नोंद", style: TextStyle(color: Colors.white)), content: Column(mainAxisSize: MainAxisSize.min, children: [
      TextField(decoration: InputDecoration(labelText: "नाव", labelStyle: TextStyle(color: Colors.white54)), style: TextStyle(color: Colors.white), onChanged: (v)=>name=v),
      TextField(decoration: InputDecoration(labelText: "रक्कम", labelStyle: TextStyle(color: Colors.white54)), style: TextStyle(color: Colors.white), keyboardType: TextInputType.number, onChanged: (v)=>amt=v),
      DropdownButton<String>(value: type, dropdownColor: Color(0xFF1A1F2B), style: TextStyle(color: Colors.white), items: ["देणे","घेणे"].map((e)=>DropdownMenuItem(value:e, child: Text(e))).toList(), onChanged: (v)=>setS(()=>type=v!)),
    ]), actions: [ElevatedButton(onPressed: (){ if(name.isNotEmpty && amt.isNotEmpty){ addUdhaar(name, amt, type); Navigator.pop(c);} }, child: Text("जतन करा"))])));
  }
  Widget buildLedger(){ return Scaffold(backgroundColor: Color(0xFF0B0E14), appBar: AppBar(backgroundColor: Color(0xFF0B0E14), title: Text("सर्व नोंदी", style: TextStyle(color: Colors.white))), body: ListView(children: exps.map((e)=> tile(e.title, "₹${e.amount}", e.cat)).toList())); }
  Widget buildChart(){ return Scaffold(backgroundColor: Color(0xFF0B0E14), appBar: AppBar(backgroundColor: Color(0xFF0B0E14), title: Text("चार्ट", style: TextStyle(color: Colors.white))), body: Padding(padding: EdgeInsets.all(16), child: Container(height: 240, padding: EdgeInsets.all(12), decoration: BoxDecoration(color: Color(0xFF1A1F2B), borderRadius: BorderRadius.circular(20)), child: BarChart(BarChartData(barGroups: List.generate(7, (i){ return BarChartGroupData(x:i, barRods: [BarChartRodData(toY: (i+3)*50.0, color: Color(0xFF00E676), width: 16, borderRadius: BorderRadius.circular(6))]); })))))); }
}
