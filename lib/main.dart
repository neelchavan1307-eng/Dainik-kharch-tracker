import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' as math;

void main() => runApp(MaterialApp(debugShowCheckedModeBanner: false, home: DainikKharchApp()));

class Expense {
  String id, title, category, payment, type; double amount; DateTime date;
  Expense({required this.id, required this.title, required this.amount, required this.category, required this.payment, required this.type, required this.date});
  Map toJson() => {'id':id,'title':title,'amount':amount,'category':category,'payment':payment,'type':type,'date':date.toIso8601String()};
  factory Expense.fromJson(Map j) => Expense(id:j['id'], title:j['title'], amount:(j['amount'] as num).toDouble(), category:j['category'], payment:j['payment'], type:j['type'], date:DateTime.parse(j['date']));
}

class DainikKharchApp extends StatefulWidget { @override State<DainikKharchApp> createState()=>_DState(); }

class _DState extends State<DainikKharchApp> with TickerProviderStateMixin {
  List<Expense> allExpenses = []; DateTime selectedDate = DateTime.now(); int tab = 0;
  double monthlyBudget = 20000; late AnimationController _animCtrl;
  PageController _pageCtrl = PageController(viewportFraction: 0.85);

  final quickPresets = [
    {"title":"चहा व नाश्ता","icon":"☕","cat":"खाद्य","amt":30.0,"color":0xFFFF8A65},
    {"title":"दूध व भाजीपाला","icon":"🥛","cat":"किराणा","amt":120.0,"color":0xFF81C784},
    {"title":"पेट्रोल / रिक्षा","icon":"⛽","cat":"प्रवास","amt":100.0,"color":0xFF64B5F6},
    {"title":"जेवण / टिफिन","icon":"🍱","cat":"खाद्य","amt":80.0,"color":0xFFFFB74D},
    {"title":"किराणा सामान","icon":"🛒","cat":"किराणा","amt":500.0,"color":0xFFBA68C8},
    {"title":"मोबाइल बिल","icon":"💡","cat":"बिल","amt":300.0,"color":0xFF4DB6AC},
  ];

  @override void initState(){ super.initState(); load(); _animCtrl = AnimationController(vsync: this, duration: Duration(milliseconds: 1200))..repeat(reverse: true); }
  Future<void> load() async { final p = await SharedPreferences.getInstance(); final s = p.getString('expenses'); if(s!=null){ setState(()=> allExpenses = (jsonDecode(s) as List).map((e)=>Expense.fromJson(e)).toList()); } }
  Future<void> save() async { final p = await SharedPreferences.getInstance(); p.setString('expenses', jsonEncode(allExpenses.map((e)=>e.toJson()).toList())); }
  void addExpense(String title, double amt, String cat){ setState(()=> allExpenses.insert(0, Expense(id: DateTime.now().millisecondsSinceEpoch.toString(), title:title, amount:amt, category:cat, payment:'UPI', type:'खर्च', date:selectedDate))); save(); }
  bool isSameDay(DateTime a, DateTime b) => a.year==b.year && a.month==b.month && a.day==b.day;
  double get todayExpense => allExpenses.where((e)=> isSameDay(e.date, selectedDate)).fold(0, (s,e)=>s+e.amount);

  @override Widget build(BuildContext context){
    return Scaffold(
      backgroundColor: Color(0xFF0B0E14),
      body: tab==0? build3DDashboard() : tab==1? buildLedger() : buildAnalytics(),
      bottomNavigationBar: Container(
        margin: EdgeInsets.all(16), padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(color: Color(0xFF1A1F2B), borderRadius: BorderRadius.circular(30), boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 20, offset: Offset(0,10))]),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          _3DNavItem(Icons.dashboard_rounded, "आज", 0), _3DNavItem(Icons.list_alt_rounded, "नोंदी", 1), _3DNavItem(Icons.pie_chart_rounded, "चार्ट", 2),
        ]),
      ),
    );
  }

  Widget _3DNavItem(IconData ic, String lb, int idx){
    bool sel = tab==idx;
    return GestureDetector(onTap: ()=>setState(()=>tab=idx), child: AnimatedContainer(duration: Duration(milliseconds: 300),
      padding: EdgeInsets.symmetric(horizontal: 22, vertical: 12),
      decoration: BoxDecoration(color: sel?Color(0xFF00E676):Colors.transparent, borderRadius: BorderRadius.circular(20), boxShadow: sel?[BoxShadow(color: Color(0xFF00E676).withOpacity(0.5), blurRadius: 15, offset: Offset(0,5))]:[]),
      child: Row(children: [Icon(ic, color: sel?Colors.black:Colors.white54), if(sel) SizedBox(width: 6), if(sel) Text(lb, style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold))]),
    ));
  }

  Widget build3DDashboard(){
    return CustomScrollView(slivers: [
      SliverAppBar(expandedHeight: 380, pinned: true, backgroundColor: Colors.transparent, flexibleSpace: FlexibleSpaceBar(background: Stack(children: [
        Container(decoration: BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF0A1F14), Color(0xFF1B3A2A)], begin: Alignment.topLeft, end: Alignment.bottomRight))),
        // 3D Banner Card
        Positioned(left: 16, right: 16, top: 80, child: Transform(perspective: 0.001, rotateX: 0.1, child: Container(
          height: 180, padding: EdgeInsets.all(20),
          decoration: BoxDecoration(gradient: LinearGradient(colors: [Color(0xFFD4FF5A), Color(0xFF8BC34A)]), borderRadius: BorderRadius.circular(28), boxShadow: [BoxShadow(color: Color(0xFFD4FF5A).withOpacity(0.4), blurRadius: 30, offset: Offset(0,15))]),
          child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(20)), child: Text("मराठी खर्च व बचत डायरी", style: TextStyle(color: Color(0xFFD4FF5A), fontSize: 10))),
              SizedBox(height: 8), Text("दैनिक खर्च", style: GoogleFonts.poppins(fontSize: 26, fontWeight: FontWeight.w900)),
              Text("तुमचा रोजचा जमा-खर्च आणि बचत साथीदार", style: TextStyle(fontSize: 11)),
            ])),
            Transform.translate(offset: Offset(0, -10), child: Text("₹", style: TextStyle(fontSize: 80, fontWeight: FontWeight.bold, color: Colors.black.withOpacity(0.15)))),
          ]),
        ))),
        // 3 Floating 3D Stats
        Positioned(left: 16, right: 16, bottom: 20, child: Row(children: [
          _3DStatCard("आजचा खर्च", "₹${todayExpense.toInt()}", Color(0xFFFF6B6B)),
          SizedBox(width: 12),
          _3DStatCard("शिल्लक", "₹${(monthlyBudget-todayExpense).toInt()}", Color(0xFF00E676)),
        ]))
      ]))),
      SliverToBoxAdapter(child: Padding(padding: EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text("३-डी झटपट नोंद - दाबा आणि पहा जादू", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
        SizedBox(height: 16),
        SizedBox(height: 160, child: PageView.builder(controller: _pageCtrl, itemCount: quickPresets.length, itemBuilder: (c,i){
          var q = quickPresets[i];
          return AnimatedBuilder(animation: _pageCtrl, builder: (ctx, child){
            double val = 0; if(_pageCtrl.position.haveDimensions){ val = (_pageCtrl.page! - i); val = (1 - (val.abs() * 0.3)).clamp(0.8, 1.0); }
            else val = 1;
            return Transform.scale(scale: val, child: _3DPresetCard(q));
          });
        })),
        SizedBox(height: 20),
        Text("आजच्या 3D नोंदी", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
       ...allExpenses.where((e)=>isSameDay(e.date, selectedDate)).map((e)=> _3DExpenseTile(e)).toList(),
        SizedBox(height: 100),
      ])))
    ]);
  }

  Widget _3DStatCard(String t, String a, Color col){
    return Expanded(child: Container(padding: EdgeInsets.all(16), decoration: BoxDecoration(color: Color(0xFF1A1F2B), borderRadius: BorderRadius.circular(20), border: Border.all(color: col.withOpacity(0.3)), boxShadow: [BoxShadow(color: col.withOpacity(0.2), blurRadius: 20, offset: Offset(0,8)), BoxShadow(color: Colors.black54, blurRadius: 10, offset: Offset(0,4))]), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Container(width: 32, height: 32, decoration: BoxDecoration(color: col, borderRadius: BorderRadius.circular(10), boxShadow: [BoxShadow(color: col, blurRadius: 10)]), child: Icon(Icons.account_balance_wallet, size: 18, color: Colors.black)), SizedBox(height: 10), Text(t, style: TextStyle(color: Colors.white54, fontSize: 10)), Text(a, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)) ])));
  }

  Widget _3DPresetCard(Map q){
    return GestureDetector(onTap: ()=> addExpense(q['title'], q['amt'], q['cat']), child: Container(margin: EdgeInsets.symmetric(horizontal: 8, vertical: 10), decoration: BoxDecoration(gradient: LinearGradient(colors: [Color(q['color']), Color(q['color']).withOpacity(0.6)]), borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Color(q['color']).withOpacity(0.5), blurRadius: 20, offset: Offset(0,12)), BoxShadow(color: Colors.black45, blurRadius: 10)]), child: Stack(children: [
      Positioned(right: -10, bottom: -10, child: Text(q['icon'], style: TextStyle(fontSize: 80, color: Colors.black.withOpacity(0.15)))),
      Padding(padding: EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(q['icon'], style: TextStyle(fontSize: 32)), Spacer(), Text(q['title'], style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13)), Text("₹${q['amt']}", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16))]),
    ]))),
    );
  }

  Widget _3DExpenseTile(Expense e){
    return Container(margin: EdgeInsets.symmetric(vertical: 6), padding: EdgeInsets.all(14), decoration: BoxDecoration(color: Color(0xFF1A1F2B), borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black45, blurRadius: 8, offset: Offset(0,4))]), child: Row(children: [Container(padding: EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(12)), child: Text("₹", style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold))), SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(e.title, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), Text(e.category, style: TextStyle(color: Colors.white38, fontSize: 11))])), Text("₹${e.amount.toInt()}", style: TextStyle(color: Color(0xFF00E676), fontWeight: FontWeight.bold))]));
  }

  Widget buildLedger(){ return Scaffold(backgroundColor: Color(0xFF0B0E14), appBar: AppBar(backgroundColor: Color(0xFF0B0E14), title: Text("सर्व 3D नोंदी", style: TextStyle(color: Colors.white))), body: ListView(children: allExpenses.map((e)=> _3DExpenseTile(e)).toList())); }
  Widget buildAnalytics(){ return Scaffold(backgroundColor: Color(0xFF0B0E14), appBar: AppBar(backgroundColor: Color(0xFF0B0E14), title: Text("3D विश्लेषण", style: TextStyle(color: Colors.white))), body: Padding(padding: EdgeInsets.all(16), child: Container(height: 250, padding: EdgeInsets.all(16), decoration: BoxDecoration(color: Color(0xFF1A1F2B), borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 20)]), child: BarChart(BarChartData(barGroups: List.generate(7, (i){ double amt = allExpenses.length>i? allExpenses[i].amount : (math.Random().nextInt(500).toDouble()); return BarChartGroupData(x:i, barRods: [BarChartRodData(toY: amt, color: Color(0xFF00E676), width: 18, borderRadius: BorderRadius.circular(8))]); })))))); }
}

extension Transform on Widget { static Widget perspective(double p, {double rotateX=0, required Widget child}){ return Transform(transform: Matrix4.identity()..setEntry(3,2,p)..rotateX(rotateX), alignment: FractionalOffset.center, child: child); } }
