import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(MaterialApp(debugShowCheckedModeBanner: false, home: DainikKharchApp()));

class Expense {
  String id, title, category, amount, payment, type;
  DateTime date;
  Expense({required this.id, required this.title, required this.amount, required this.category, required this.payment, required this.type, required this.date});
  Map toJson() => {'id':id,'title':title,'amount':amount,'category':category,'payment':payment,'type':type,'date':date.toIso8601String()};
  factory Expense.fromJson(Map j) => Expense(id:j['id'], title:j['title'].toString(), amount:j['amount'].toString(), category:j['category'], payment:j['payment'], type:j['type'], date:DateTime.parse(j['date']));
}

class DainikKharchApp extends StatefulWidget { @override State<DainikKharchApp> createState()=>_DState(); }

class _DState extends State<DainikKharchApp> {
  List<Expense> allExpenses = [];
  DateTime selectedDate = DateTime.now();
  int tab = 0;
  double monthlyBudget = 20000;
  PageController pageCtrl = PageController(viewportFraction: 0.88);

  final quickPresets = [
    {"title":"चहा व नाश्ता","icon":"☕","cat":"खाद्य","amt":"30","color":Colors.orange},
    {"title":"दूध भाजीपाला","icon":"🥛","cat":"किराणा","amt":"120","color":Colors.green},
    {"title":"पेट्रोल / रिक्षा","icon":"⛽","cat":"प्रवास","amt":"100","color":Colors.blue},
    {"title":"जेवण टिफिन","icon":"🍱","cat":"खाद्य","amt":"80","color":Colors.amber},
    {"title":"किराणा सामान","icon":"🛒","cat":"किराणा","amt":"500","color":Colors.purple},
    {"title":"लाईट बिल","icon":"💡","cat":"बिल","amt":"300","color":Colors.teal},
  ];

  @override void initState(){ super.initState(); load(); }
  Future<void> load() async { final p = await SharedPreferences.getInstance(); final s = p.getString('expenses'); if(s!=null){ setState(()=> allExpenses = (jsonDecode(s) as List).map((e)=>Expense.fromJson(e)).toList()); } }
  Future<void> save() async { final p = await SharedPreferences.getInstance(); p.setString('expenses', jsonEncode(allExpenses.map((e)=>e.toJson()).toList())); }
  void addExp(String title, String amt, String cat){ setState(()=> allExpenses.insert(0, Expense(id: DateTime.now().millisecondsSinceEpoch.toString(), title:title, amount:amt, category:cat, payment:'UPI', type:'खर्च', date:selectedDate))); save(); }
  bool isSameDay(DateTime a, DateTime b) => a.year==b.year && a.month==b.month && a.day==b.day;

  @override Widget build(BuildContext context){
    return Scaffold(
      backgroundColor: Color(0xFF0B0E14),
      body: tab==0? buildDashboard() : tab==1? buildLedger() : buildAnalytics(),
      bottomNavigationBar: Container(
        margin: EdgeInsets.all(16), padding: EdgeInsets.all(8),
        decoration: BoxDecoration(color: Color(0xFF1A1F2B), borderRadius: BorderRadius.circular(30), boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 20)]),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          navBtn(Icons.dashboard, "आज", 0), navBtn(Icons.list_alt, "नोंदी", 1), navBtn(Icons.pie_chart, "चार्ट", 2),
        ]),
      ),
    );
  }

  Widget navBtn(IconData ic, String lb, int idx){
    bool sel = tab==idx;
    return GestureDetector(onTap: ()=>setState(()=>tab=idx), child: AnimatedContainer(duration: Duration(milliseconds: 250), padding: EdgeInsets.symmetric(horizontal: 22, vertical: 12), decoration: BoxDecoration(color: sel?Color(0xFF00E676):Colors.transparent, borderRadius: BorderRadius.circular(20), boxShadow: sel?[BoxShadow(color: Color(0xFF00E676).withOpacity(0.4), blurRadius: 12)]:[]), child: Icon(ic, color: sel?Colors.black:Colors.white54)));
  }

  Widget buildDashboard(){
    double todayAmt = 0; for(var e in allExpenses){ if(isSameDay(e.date, selectedDate)) todayAmt += double.tryParse(e.amount)??0; }
    return CustomScrollView(slivers: [
      SliverAppBar(expandedHeight: 360, pinned: true, backgroundColor: Color(0xFF0B0E14), flexibleSpace: FlexibleSpaceBar(background: Stack(children: [
        Container(color: Color(0xFF0B0E14)),
        Positioned(left: 16, right: 16, top: 70, child: Container(
          height: 175, padding: EdgeInsets.all(18),
          decoration: BoxDecoration(gradient: LinearGradient(colors: [Color(0xFFD4FF5A), Color(0xFF9CCC65)]), borderRadius: BorderRadius.circular(26), boxShadow: [BoxShadow(color: Color(0xFFD4FF5A).withOpacity(0.3), blurRadius: 25, offset: Offset(0,15))]),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(12)), child: Text("मराठी खर्च व बचत डायरी", style: TextStyle(color: Color(0xFFD4FF5A), fontSize: 10))),
            SizedBox(height: 10), Text("दैनिक खर्च", style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.black)),
            Text("तुमचा रोजचा जमा-खर्च आणि बचत साथीदार", style: TextStyle(fontSize: 11, color: Colors.black87)),
          ]),
        )),
        Positioned(left: 16, right: 16, bottom: 15, child: Row(children: [
          statCard("आजचा खर्च", "₹${todayAmt.toInt()}", Colors.redAccent),
          SizedBox(width: 12),
          statCard("शिल्लक", "₹${(monthlyBudget - todayAmt).toInt()}", Color(0xFF00E676)),
        ]))
      ]))),
      SliverToBoxAdapter(child: Padding(padding: EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text("३-डी झटपट नोंद", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
        SizedBox(height: 12),
        SizedBox(height: 150, child: PageView.builder(controller: pageCtrl, itemCount: quickPresets.length, itemBuilder: (c,i){
          var q = quickPresets[i];
          return Transform.translate(offset: Offset(0, 0), child: GestureDetector(onTap: ()=> addExp(q['title'].toString(), q['amt'].toString(), q['cat'].toString()), child: Container(
            margin: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(color: q['color'] as Color, borderRadius: BorderRadius.circular(22), boxShadow: [BoxShadow(color: (q['color'] as Color).withOpacity(0.5), blurRadius: 18, offset: Offset(0,10)), BoxShadow(color: Colors.black45, blurRadius: 8)]),
            child: Stack(children: [
              Positioned(right: -5, bottom: -5, child: Text(q['icon'].toString(), style: TextStyle(fontSize: 70, color: Colors.black12))),
              Padding(padding: EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(q['icon'].toString(), style: TextStyle(fontSize: 30)), Spacer(), Text(q['title'].toString(), style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 12)), Text("₹${q['amt']}", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16))
              ])),
            ]),
          )));
        })),
        SizedBox(height: 18),
        Text("आजच्या नोंदी", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
       ...allExpenses.where((e)=>isSameDay(e.date, selectedDate)).map((e)=> expenseTile(e)).toList(),
        SizedBox(height: 90),
      ])))
    ]);
  }

  Widget statCard(String t, String a, Color col){
    return Expanded(child: Container(padding: EdgeInsets.all(14), decoration: BoxDecoration(color: Color(0xFF1A1F2B), borderRadius: BorderRadius.circular(18), border: Border.all(color: col.withOpacity(0.2)), boxShadow: [BoxShadow(color: Colors.black45, blurRadius: 10)]), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(width: 28, height: 28, decoration: BoxDecoration(color: col, borderRadius: BorderRadius.circular(8)), child: Icon(Icons.wallet, size: 16, color: Colors.black)), SizedBox(height: 8), Text(t, style: TextStyle(color: Colors.white54, fontSize: 10)), Text(a, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold))
    ])));
  }

  Widget expenseTile(Expense e){
    return Container(margin: EdgeInsets.symmetric(vertical: 5), padding: EdgeInsets.all(12), decoration: BoxDecoration(color: Color(0xFF1A1F2B), borderRadius: BorderRadius.circular(14)), child: Row(children: [
      Container(padding: EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(10)), child: Text("₹", style: TextStyle(color: Colors.greenAccent))),
      SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(e.title, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)), Text(e.category, style: TextStyle(color: Colors.white38, fontSize: 10))])), Text("₹${e.amount}", style: TextStyle(color: Color(0xFF00E676), fontWeight: FontWeight.bold))
    ]));
  }

  Widget buildLedger(){ return Scaffold(backgroundColor: Color(0xFF0B0E14), appBar: AppBar(backgroundColor: Color(0xFF0B0E14), title: Text("सर्व नोंदी", style: TextStyle(color: Colors.white))), body: ListView(children: allExpenses.map((e)=> expenseTile(e)).toList())); }

  Widget buildAnalytics(){
    return Scaffold(backgroundColor: Color(0xFF0B0E14), appBar: AppBar(backgroundColor: Color(0xFF0B0E14), title: Text("विश्लेषण", style: TextStyle(color: Colors.white))), body: Padding(padding: EdgeInsets.all(16), child: Container(height: 240, padding: EdgeInsets.all(12), decoration: BoxDecoration(color: Color(0xFF1A1F2B), borderRadius: BorderRadius.circular(20)), child: BarChart(BarChartData(barGroups: List.generate(7, (i){ return BarChartGroupData(x:i, barRods: [BarChartRodData(toY: (i+2)*80.0, color: Color(0xFF00E676), width: 16, borderRadius: BorderRadius.circular(6))]); }))))));
  }
}
