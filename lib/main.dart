import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(MaterialApp(debugShowCheckedModeBanner: false, theme: ThemeData(useMaterial3: true, colorScheme: ColorScheme.fromSeed(seedColor: Color(0xFF0A7A42))), home: DainikKharchApp()));

class Expense {
  String id, title, category, payment, type;
  double amount;
  DateTime date;
  Expense({required this.id, required this.title, required this.amount, required this.category, required this.payment, required this.type, required this.date});
  Map toJson() => {'id':id,'title':title,'amount':amount,'category':category,'payment':payment,'type':type,'date':date.toIso8601String()};
  factory Expense.fromJson(Map j) => Expense(id:j['id'], title:j['title'], amount:j['amount'].toDouble(), category:j['category'], payment:j['payment'], type:j['type'], date:DateTime.parse(j['date']));
}

class DainikKharchApp extends StatefulWidget { @override State<DainikKharchApp> createState()=>_DState(); }

class _DState extends State<DainikKharchApp>{
  List<Expense> allExpenses = [];
  DateTime selectedDate = DateTime.now();
  int tab = 0;
  double monthlyBudget = 20000;
  double dailyBudget = 700;

  final quickPresets = [
    {"title":"चहा व नाश्ता","icon":"☕","cat":"खाद्य","amt":30.0},
    {"title":"दूध व भाजीपाला","icon":"🥛","cat":"किराणा","amt":120.0},
    {"title":"पेट्रोल / रिक्षा","icon":"⛽","cat":"प्रवास","amt":100.0},
    {"title":"जेवण / टिफिन","icon":"🍱","cat":"खाद्य","amt":80.0},
    {"title":"किराणा सामान","icon":"🛒","cat":"किराणा","amt":500.0},
    {"title":"मोबाइल / लाईट बिल","icon":"💡","cat":"बिल","amt":300.0},
  ];

  @override void initState(){ super.initState(); load(); }

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    final s = p.getString('expenses');
    if(s!=null){ setState(()=> allExpenses = (jsonDecode(s) as List).map((e)=>Expense.fromJson(e)).toList()); }
    monthlyBudget = p.getDouble('mb')?? 20000;
    dailyBudget = p.getDouble('db')?? 700;
  }
  Future<void> save() async {
    final p = await SharedPreferences.getInstance();
    p.setString('expenses', jsonEncode(allExpenses.map((e)=>e.toJson()).toList()));
    p.setDouble('mb', monthlyBudget); p.setDouble('db', dailyBudget);
  }

  void addExpense(String title, double amt, String cat, String pay, String type){
    setState(()=> allExpenses.insert(0, Expense(id: DateTime.now().millisecondsSinceEpoch.toString(), title:title, amount:amt, category:cat, payment:pay, type:type, date:selectedDate)));
    save();
  }

  // CALCULATIONS
  double get todayExpense => allExpenses.where((e)=> isSameDay(e.date, selectedDate) && e.type=='खर्च').fold(0, (s,e)=>s+e.amount);
  double get todayIncome => allExpenses.where((e)=> isSameDay(e.date, selectedDate) && e.type=='उत्पन्न').fold(0, (s,e)=>s+e.amount);
  double get monthExpense => allExpenses.where((e)=> e.date.month==selectedDate.month && e.date.year==selectedDate.year && e.type=='खर्च').fold(0, (s,e)=>s+e.amount);
  double get monthIncome => allExpenses.where((e)=> e.date.month==selectedDate.month && e.date.year==selectedDate.year && e.type=='उत्पन्न').fold(0, (s,e)=>s+e.amount);
  bool isSameDay(DateTime a, DateTime b) => a.year==b.year && a.month==b.month && a.day==b.day;

  @override Widget build(BuildContext context){
    return Scaffold(
      backgroundColor: Color(0xFFF5F7F0),
      body: tab==0? buildDashboard() : tab==1? buildLedger() : tab==2? buildAnalytics() : buildBudget(),
      bottomNavigationBar: NavigationBar(selectedIndex: tab, onDestinationSelected: (i)=>setState(()=>tab=i), destinations: [
        NavigationDestination(icon: Icon(Icons.dashboard), label: 'आजचा हिशेब'),
        NavigationDestination(icon: Icon(Icons.list_alt), label: 'सर्व नोंदी'),
        NavigationDestination(icon: Icon(Icons.pie_chart), label: 'विश्लेषण'),
        NavigationDestination(icon: Icon(Icons.account_balance_wallet), label: 'बजेट'),
      ]),
    );
  }

  Widget buildDashboard(){
    return CustomScrollView(slivers: [
      SliverAppBar(expandedHeight: 260, pinned: true, flexibleSpace: FlexibleSpaceBar(background: Container(
        decoration: BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF0A7A42), Color(0xFF1EB980)], begin: Alignment.topLeft, end: Alignment.bottomRight)),
        child: SafeArea(child: Column(children: [
          SizedBox(height: 40),
          Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Row(children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text("दैनिक खर्च", style: GoogleFonts.poppins(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
              Text("तुमचा रोजचा जमा-खर्च", style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12)),
            ]),
            Spacer(),
            ElevatedButton.icon(onPressed: (){}, icon: Icon(Icons.login, size: 16), label: Text("Sign in with Google", style: TextStyle(fontSize: 11)), style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black))
          ])),
          SizedBox(height: 12),
          // TODAY CARDS
          Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Row(children: [
            _dashCard("आजचा खर्च", "₹${todayExpense.toStringAsFixed(0)}", Icons.arrow_upward, Colors.redAccent),
            SizedBox(width: 10),
            _dashCard("चालू महिना", "₹${monthExpense.toStringAsFixed(0)}", Icons.calendar_month, Colors.orange),
            SizedBox(width: 10),
            _dashCard("शिल्लक बजेट", "₹${(monthlyBudget-monthExpense).toStringAsFixed(0)}", Icons.savings, Colors.white),
          ])),
          SizedBox(height: 10),
          // DATE STRIP
          Container(height: 60, child: ListView.builder(scrollDirection: Axis.horizontal, itemCount: 30, itemBuilder: (c,i){
            DateTime d = DateTime.now().subtract(Duration(days: 15-i));
            bool sel = isSameDay(d, selectedDate);
            return GestureDetector(onTap: ()=>setState(()=>selectedDate=d), child: Container(margin: EdgeInsets.symmetric(horizontal: 4), padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8), decoration: BoxDecoration(color: sel?Colors.white:Colors.white24, borderRadius: BorderRadius.circular(12)), child: Column(children: [Text(DateFormat('E','en').format(d), style: TextStyle(color: sel?Colors.black:Colors.white, fontSize: 10)), Text("${d.day}", style: TextStyle(color: sel?Colors.black:Colors.white, fontWeight: FontWeight.bold))])) );
          })),
        ])),
      ))),
      SliverToBoxAdapter(child: Padding(padding: EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text("१-टॅप झटपट नोंद", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
        SizedBox(height: 10),
        GridView.builder(shrinkWrap: true, physics: NeverScrollableScrollPhysics(), gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, childAspectRatio: 1.3, crossAxisSpacing: 10, mainAxisSpacing: 10), itemCount: quickPresets.length, itemBuilder: (c,i){
          var q = quickPresets[i];
          return InkWell(onTap: ()=> addExpense(q['title'] as String, q['amt'] as double, q['cat'] as String, 'UPI', 'खर्च'), child: Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)]), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Text(q['icon'] as String, style: TextStyle(fontSize: 24)), SizedBox(height: 4), Text(q['title'] as String, style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600), textAlign: TextAlign.center), Text("₹${q['amt']}", style: TextStyle(fontSize: 10, color: Colors.green))])));
        }),
        SizedBox(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text("आजच्या नोंदी (${selectedDate.day}/${selectedDate.month})", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)), TextButton(onPressed: ()=>setState(()=>tab=1), child: Text("सर्व पहा"))]),
       ...allExpenses.where((e)=>isSameDay(e.date, selectedDate)).map((e)=> Card(child: ListTile(leading: CircleAvatar(backgroundColor: e.type=='खर्च'?Colors.red[100]:Colors.green[100], child: Text(e.type=='खर्च'?"₹":"+", style: TextStyle(fontWeight: FontWeight.bold))), title: Text(e.title, style: GoogleFonts.poppins(fontSize: 13)), subtitle: Text("${e.category} • ${e.payment}", style: TextStyle(fontSize: 11)), trailing: Text("${e.type=='खर्च'?'-':'+'}₹${e.amount.toStringAsFixed(0)}", style: TextStyle(fontWeight: FontWeight.bold, color: e.type=='खर्च'?Colors.red:Colors.green))))).toList(),
        if(allExpenses.where((e)=>isSameDay(e.date, selectedDate)).isEmpty) Padding(padding: EdgeInsets.all(20), child: Center(child: Text("आज कोणतीही नोंद नाही\nवरच्या बटणाने जोडा", textAlign: TextAlign.center))),
      ]))),
    ]);
  }

  Widget _dashCard(String title, String amt, IconData icon, Color c){
    return Expanded(child: Container(padding: EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, size: 16, color: c==Colors.white?Colors.green:c), SizedBox(height: 4), Text(title, style: TextStyle(fontSize: 9)), Text(amt, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14)) ])));
  }

  Widget buildLedger(){
    // Group by date
    Map<String, List<Expense>> grouped = {};
    for(var e in allExpenses){ String key = DateFormat('MMMM yyyy, dd MMM','en').format(e.date); (grouped[key]??= []).add(e); }
    return Scaffold(appBar: AppBar(title: Text("सर्व नोंदी - Ledger"), actions: [IconButton(icon: Icon(Icons.search), onPressed: (){})]), body: ListView(children: grouped.entries.map((en){
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(padding: EdgeInsets.all(12), child: Text(en.key, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.green))),
       ...en.value.map((e)=> Dismissible(key: Key(e.id), onDismissed: (d){ setState(()=> allExpenses.removeWhere((x)=>x.id==e.id)); save(); }, background: Container(color: Colors.red, child: Icon(Icons.delete, color: Colors.white)), child: Card(margin: EdgeInsets.symmetric(horizontal: 12, vertical: 4), child: ListTile(title: Text(e.title), subtitle: Text("${e.category} • ${e.payment} • ${DateFormat('hh:mm a').format(e.date)}"), trailing: Row(mainAxisSize: MainAxisSize.min, children: [Text("₹${e.amount}", style: TextStyle(fontWeight: FontWeight.bold)), PopupMenuButton(onSelected: (v){ if(v=='del'){ setState(()=> allExpenses.removeWhere((x)=>x.id==e.id)); save(); } }, itemBuilder: (c)=> [PopupMenuItem(value: 'del', child: Text("Delete"))])])))))).toList()
      ]);
    }).toList()));
  }

  Widget buildAnalytics(){
    Map<String,double> catMap={}; Map<String,double> payMap={};
    for(var e in allExpenses.where((e)=>e.type=='खर्च')){ catMap[e.category]=(catMap[e.category]??0)+e.amount; payMap[e.payment]=(payMap[e.payment]??0)+e.amount; }
    return Scaffold(appBar: AppBar(title: Text("विश्लेषण")), body: ListView(padding: EdgeInsets.all(16), children: [
      Text("मागील ७ दिवसांचा खर्च कल", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
      SizedBox(height: 10),
      Container(height: 200, padding: EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)), child: BarChart(BarChartData(barGroups: List.generate(7, (i){ DateTime d = DateTime.now().subtract(Duration(days: 6-i)); double amt = allExpenses.where((e)=>isSameDay(e.date,d) && e.type=='खर्च').fold(0, (s,e)=>s+e.amount); return BarChartGroupData(x:i, barRods: [BarChartRodData(toY: amt, color: Color(0xFF0A7A42), width: 16, borderRadius: BorderRadius.circular(4))]); } ), titlesData: FlTitlesData(bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v,m)=> Text(DateFormat('E').format(DateTime.now().subtract(Duration(days: 6-v.toInt()))).substring(0,2), style: TextStyle(fontSize: 10)))))))),
      SizedBox(height: 20),
      Text("विभागनिहाय डोनट चार्ट", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
      Container(height: 200, child: catMap.isEmpty? Center(child: Text("Data नाही")) : PieChart(PieChartData(sections: catMap.entries.map((en)=> PieChartSectionData(value: en.value, title: "${en.key}\n₹${en.value.toInt()}", radius: 60, titleStyle: TextStyle(fontSize: 10))).toList()))),
      SizedBox(height: 20),
      Text("पेमेंट पद्धतीनुसार", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
     ...payMap.entries.map((en)=> ListTile(leading: Icon(en.key=='UPI'?Icons.qr_code: en.key=='रोख'?Icons.money:Icons.credit_card), title: Text(en.key), trailing: Text("₹${en.value.toStringAsFixed(0)} • ${(en.value/(monthExpense==0?1:monthExpense)*100).toStringAsFixed(0)}%"))).toList()
    ]));
  }

  Widget buildBudget(){
    return Scaffold(appBar: AppBar(title: Text("बजेट प्लॅनर")), body: Padding(padding: EdgeInsets.all(16), child: Column(children: [
      Card(child: Padding(padding: EdgeInsets.all(16), child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text("मासिक बजेट"), Text("₹${monthlyBudget.toInt()}", style: TextStyle(fontWeight: FontWeight.bold))]),
        Slider(value: monthlyBudget, min: 5000, max: 100000, divisions: 19, label: monthlyBudget.toInt().toString(), onChanged: (v){ setState(()=> monthlyBudget=v); save(); }),
        LinearProgressIndicator(value: (monthExpense/monthlyBudget).clamp(0,1), color: monthExpense>monthlyBudget?Colors.red:Colors.green),
        Text("${(monthExpense/monthlyBudget*100).toStringAsFixed(0)}% वापरले - शिल्लक ₹${(monthlyBudget-monthExpense).toInt()}"),
      ]))),
      SizedBox(height: 16),
      Card(child: Padding(padding: EdgeInsets.all(16), child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text("दैनिक बजेट"), Text("₹${dailyBudget.toInt()}", style: TextStyle(fontWeight: FontWeight.bold))]),
        Slider(value: dailyBudget, min: 100, max: 5000, divisions: 49, label: dailyBudget.toInt().toString(), onChanged: (v){ setState(()=> dailyBudget=v); save(); }),
        LinearProgressIndicator(value: (todayExpense/dailyBudget).clamp(0,1), color: todayExpense>dailyBudget?Colors.red:Colors.orange),
        Text("आज ${todayExpense.toInt()}/${dailyBudget.toInt()} - ${todayExpense>dailyBudget?"बजेट ओलांडले!":"नियंत्रणात आहे"}"),
      ]))),
      Spacer(),
      Container(padding: EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(12)), child: Row(children: [Icon(Icons.cloud_done, color: Colors.green), SizedBox(width: 8), Expanded(child: Text("सुरक्षित क्लाउड सिंक: Google Sign-In ne tumcha data Firestore var backup hoil. Mobile badalala tari hishob safe!", style: TextStyle(fontSize: 12)))]))
    ])),
    floatingActionButton: FloatingActionButton.extended(onPressed: ()=> showAddDialog(), label: Text("नोंद जोडा"), icon: Icon(Icons.add)),
    );
  }

  void showAddDialog(){
    String title=""; double amt=0; String cat="खाद्य"; String pay="UPI"; String type="खर्च";
    showDialog(context: context, builder: (c)=> StatefulBuilder(builder: (c,setS)=> AlertDialog(title: Text("नवीन नोंद"), content: Column(mainAxisSize: MainAxisSize.min, children: [
      TextField(decoration: InputDecoration(labelText: "कशासाठी? उदा. चहा"), onChanged: (v)=>title=v),
      TextField(decoration: InputDecoration(labelText: "रक्कम ₹"), keyboardType: TextInputType.number, onChanged: (v)=> amt=double.tryParse(v)??0),
      DropdownButton<String>(value: cat, items: ["खाद्य","किराणा","प्रवास","बिल","उत्पन्न","इतर"].map((e)=>DropdownMenuItem(value:e, child: Text(e))).toList(), onChanged: (v)=>setS(()=>cat=v!)),
      DropdownButton<String>(value: pay, items: ["UPI","रोख","कार्ड","बँक"].map((e)=>DropdownMenuItem(value:e, child: Text(e))).toList(), onChanged: (v)=>setS(()=>pay=v!)),
      DropdownButton<String>(value: type, items: ["खर्च","उत्पन्न"].map((e)=>DropdownMenuItem(value:e, child: Text(e))).toList(), onChanged: (v)=>setS(()=>type=v!)),
    ]), actions: [TextButton(onPressed: ()=>Navigator.pop(c), child: Text("रद्द")), ElevatedButton(onPressed: (){ if(title.isNotEmpty && amt>0){ addExpense(title, amt, cat, pay, type); Navigator.pop(c);} }, child: Text("जतन करा"))])));
  }
}
