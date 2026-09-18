import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const EcetApp());

class EcetApp extends StatelessWidget {
  const EcetApp({super.key});
  @override Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner:false, title:'TG ECET 2027',
    theme:ThemeData(useMaterial3:true,colorSchemeSeed:Colors.indigo),
    home:const Shell());
}

class Shell extends StatefulWidget { const Shell({super.key}); @override State<Shell> createState()=>_ShellState(); }
class _ShellState extends State<Shell> {
  int index=0;
  @override Widget build(BuildContext c) {
    final pages=[const HomePage(),const PlanPage(),const PracticePage(),const ProgressPage()];
    return Scaffold(body:SafeArea(child:pages[index]),bottomNavigationBar:NavigationBar(
      selectedIndex:index,onDestinationSelected:(i)=>setState(()=>index=i),
      destinations:const[
        NavigationDestination(icon:Icon(Icons.home_outlined),selectedIcon:Icon(Icons.home),label:'Home'),
        NavigationDestination(icon:Icon(Icons.calendar_month_outlined),selectedIcon:Icon(Icons.calendar_month),label:'Plan'),
        NavigationDestination(icon:Icon(Icons.quiz_outlined),selectedIcon:Icon(Icons.quiz),label:'Practice'),
        NavigationDestination(icon:Icon(Icons.insights_outlined),selectedIcon:Icon(Icons.insights),label:'Progress'),
      ]));
  }
}

Future<List<dynamic>> loadJson(String file) async => jsonDecode(await rootBundle.loadString('data/$file.json'));

class HomePage extends StatefulWidget { const HomePage({super.key}); @override State<HomePage> createState()=>_HomePageState(); }
class _HomePageState extends State<HomePage>{
  int completed=0;
  @override void initState(){super.initState(); _load();}
  Future<void> _load() async { final p=await SharedPreferences.getInstance(); setState(()=>completed=p.getInt('completedDays')??0); }
  @override Widget build(BuildContext c)=>FutureBuilder<List<dynamic>>(future:loadJson('plan'),builder:(c,s){
    final today=s.hasData?s.data![completed.clamp(0,179)]:null;
    return RefreshIndicator(onRefresh:_load,child:ListView(padding:const EdgeInsets.all(18),children:[
      Row(children:[Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Text('TG ECET 2027',style:Theme.of(c).textTheme.headlineMedium?.copyWith(fontWeight:FontWeight.w800)),
        const Text('ECE • Your 180-day mission')]))]),
      const SizedBox(height:18),
      Card(child:Padding(padding:const EdgeInsets.all(20),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Text('DAY ${completed+1}',style:Theme.of(c).textTheme.labelLarge),
        const SizedBox(height:6),Text(today?['task']??'Loading...',style:Theme.of(c).textTheme.titleLarge?.copyWith(fontWeight:FontWeight.bold)),
        const SizedBox(height:14),LinearProgressIndicator(value:completed/180),
        const SizedBox(height:8),Text('$completed / 180 days completed')
      ]))),
      const SizedBox(height:14),
      Row(children:[
        Expanded(child:_stat(c,'MCQs','40+','Practice')),
        const SizedBox(width:10),Expanded(child:_stat(c,'Plan','180','Days')),
      ]),
      const SizedBox(height:14),
      Text('Quick actions',style:Theme.of(c).textTheme.titleLarge?.copyWith(fontWeight:FontWeight.bold)),
      _action(c,'Start chapter MCQs','Practice by subject and chapter',Icons.quiz,()=>Navigator.push(c,MaterialPageRoute(builder:(_)=>const PracticePage()))),
      _action(c,'Explore 180-day plan','Today → revision → mocks',Icons.calendar_month,()=>Navigator.push(c,MaterialPageRoute(builder:(_)=>const PlanPage()))),
      _action(c,'Formulas & shortcuts','Build your last-minute revision bank',Icons.functions,()=>Navigator.push(c,MaterialPageRoute(builder:(_)=>const FormulaPage()))),
    ]));
  });
  Widget _stat(BuildContext c,String a,String b,String d)=>Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(b,style:Theme.of(c).textTheme.headlineSmall?.copyWith(fontWeight:FontWeight.bold)),Text(a),Text(d,style:Theme.of(c).textTheme.bodySmall)])));
  Widget _action(BuildContext c,String t,String s,IconData i,VoidCallback f)=>Card(child:ListTile(onTap:f,leading:CircleAvatar(child:Icon(i)),title:Text(t),subtitle:Text(s),trailing:const Icon(Icons.chevron_right)));
}

class PlanPage extends StatefulWidget { const PlanPage({super.key}); @override State<PlanPage> createState()=>_PlanPageState(); }
class _PlanPageState extends State<PlanPage>{
  int completed=0;
  @override void initState(){super.initState();_load();}
  Future<void> _load()async{final p=await SharedPreferences.getInstance();setState(()=>completed=p.getInt('completedDays')??0);}
  Future<void> markDay(int d)async{final p=await SharedPreferences.getInstance();final n=d>completed?d:completed;await p.setInt('completedDays',n);setState(()=>completed=n);}
  @override Widget build(BuildContext c)=>FutureBuilder<List<dynamic>>(future:loadJson('plan'),builder:(c,s){
    if(!s.hasData)return const Center(child:CircularProgressIndicator());
    return Column(children:[Padding(padding:const EdgeInsets.all(18),child:Row(children:[Expanded(child:Text('180-Day Roadmap',style:Theme.of(c).textTheme.headlineSmall?.copyWith(fontWeight:FontWeight.bold))),Text('$completed/180')])),
    Expanded(child:ListView.builder(itemCount:s.data!.length,itemBuilder:(_,i){final x=s.data![i];final d=x['day'] as int;final done=d<=completed;return Card(margin:const EdgeInsets.symmetric(horizontal:14,vertical:4),child:ListTile(
      leading:CircleAvatar(child:Text('$d')),title:Text(x['task']),subtitle:Text(x['phase']),trailing:done?const Icon(Icons.check_circle):IconButton(icon:const Icon(Icons.check_circle_outline),onPressed:()=>markDay(d))));
    }))]);
  });
}

class PracticePage extends StatefulWidget { const PracticePage({super.key}); @override State<PracticePage> createState()=>_PracticePageState(); }
class _PracticePageState extends State<PracticePage>{
  String filter='All';
  @override Widget build(BuildContext c)=>FutureBuilder<List<dynamic>>(future:loadJson('mcqs'),builder:(c,s){
    if(!s.hasData)return const Center(child:CircularProgressIndicator());
    final all=s.data!; final subjects=['All',...{for(final x in all)x['subject'] as String}]; final shown=filter=='All'?all:all.where((x)=>x['subject']==filter).toList();
    return Column(children:[
      Padding(padding:const EdgeInsets.fromLTRB(18,18,18,8),child:Align(alignment:Alignment.centerLeft,child:Text('Practice MCQs',style:Theme.of(c).textTheme.headlineSmall?.copyWith(fontWeight:FontWeight.bold)))),
      SizedBox(height:48,child:ListView.separated(scrollDirection:Axis.horizontal,padding:const EdgeInsets.symmetric(horizontal:14),itemCount:subjects.length,itemBuilder:(_,i)=>ChoiceChip(label:Text(subjects[i]),selected:filter==subjects[i],onSelected:(_)=>setState(()=>filter=subjects[i])),separatorBuilder:(_,__)=>const SizedBox(width:8))),
      Expanded(child:ListView.builder(itemCount:shown.length,itemBuilder:(_,i)=>Card(margin:const EdgeInsets.symmetric(horizontal:14,vertical:5),child:ListTile(
        leading:CircleAvatar(child:Text('${i+1}')),title:Text(shown[i]['q']),subtitle:Text('${shown[i]['chapter']} • ${shown[i]['subject']}'),onTap:()=>Navigator.push(c,MaterialPageRoute(builder:(_)=>QuizPage(questions:shown)))))),
      FilledButton.icon(onPressed:()=>Navigator.push(c,MaterialPageRoute(builder:(_)=>QuizPage(questions:shown))),icon:const Icon(Icons.play_arrow),label:const Text('Start quiz'))
    ]);
  });
}

class QuizPage extends StatefulWidget { final List<dynamic> questions; const QuizPage({super.key,required this.questions}); @override State<QuizPage> createState()=>_QuizPageState(); }
class _QuizPageState extends State<QuizPage>{
  int q=0,score=0; int? selected; bool answered=false;
  void choose(int i){if(answered)return;setState((){selected=i;answered=true;if(i==widget.questions[q]['a'])score++;});}
  @override Widget build(BuildContext c){final x=widget.questions[q];return Scaffold(appBar:AppBar(title:Text('Question ${q+1}/${widget.questions.length}')),body:Padding(padding:const EdgeInsets.all(18),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    Text(x['subject'],style:Theme.of(c).textTheme.labelLarge),Text(x['chapter'],style:Theme.of(c).textTheme.bodySmall),const SizedBox(height:16),
    Text(x['q'],style:Theme.of(c).textTheme.titleLarge?.copyWith(fontWeight:FontWeight.bold)),const SizedBox(height:18),
    ...List.generate(x['o'].length,(i)=>Card(child:ListTile(onTap:()=>choose(i),leading:CircleAvatar(child:Text(String.fromCharCode(65+i))),title:Text(x['o'][i]),trailing:answered&&i==x['a']?const Icon(Icons.check):answered&&i==selected?const Icon(Icons.close):null))),
    if(answered)Padding(padding:const EdgeInsets.symmetric(vertical:10),child:Text(x['e'],style:const TextStyle(fontWeight:FontWeight.w500))),
    const Spacer(),SizedBox(width:double.infinity,child:FilledButton(onPressed:answered?(){if(q+1==widget.questions.length){Navigator.pushReplacement(c,MaterialPageRoute(builder:(_)=>ResultPage(score:score,total:widget.questions.length)));}else{setState((){q++;selected=null;answered=false;});}}:null,child:Text(q+1==widget.questions.length?'Finish':'Next')))
  ]));}
}

class ResultPage extends StatelessWidget{final int score,total;const ResultPage({super.key,required this.score,required this.total});@override Widget build(BuildContext c)=>Scaffold(appBar:AppBar(title:const Text('Quiz Result')),body:Center(child:Padding(padding:const EdgeInsets.all(24),child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[
  const Icon(Icons.emoji_events,size:72),const SizedBox(height:16),Text('$score / $total',style:Theme.of(c).textTheme.displaySmall?.copyWith(fontWeight:FontWeight.bold)),Text('${(score/total*100).round()}% accuracy'),const SizedBox(height:24),
  FilledButton(onPressed:()=>Navigator.pop(c),child:const Text('Back to practice'))
])));}

class ProgressPage extends StatefulWidget{const ProgressPage({super.key});@override State<ProgressPage> createState()=>_ProgressPageState();}
class _ProgressPageState extends State<ProgressPage>{int completed=0;@override void initState(){super.initState();_load();}Future<void>_load()async{final p=await SharedPreferences.getInstance();setState(()=>completed=p.getInt('completedDays')??0);} @override Widget build(BuildContext c){final pct=completed/180;return ListView(padding:const EdgeInsets.all(18),children:[
Text('Progress Dashboard',style:Theme.of(c).textTheme.headlineSmall?.copyWith(fontWeight:FontWeight.bold)),const SizedBox(height:16),
Card(child:Padding(padding:const EdgeInsets.all(20),child:Column(children:[SizedBox(width:150,height:150,child:CircularProgressIndicator(value:pct,strokeWidth:12)),const SizedBox(height:12),Text('${(pct*100).round()}% complete',style:Theme.of(c).textTheme.titleLarge),Text('$completed of 180 days')]))),
const SizedBox(height:12),const Card(child:ListTile(leading:Icon(Icons.quiz),title:Text('MCQ score tracking'),subtitle:Text('Each quiz shows score, percentage and explanations.'))),
const Card(child:ListTile(leading:Icon(Icons.save),title:Text('Progress is saved'),subtitle:Text('Your completed-day count is stored locally on the device.'))),
];}}
class FormulaPage extends StatelessWidget{const FormulaPage({super.key});@override Widget build(BuildContext c)=>Scaffold(appBar:AppBar(title:const Text('Formulas & Shortcuts')),body:ListView(padding:const EdgeInsets.all(18),children:const[
Card(child:ListTile(title:Text('Ohm’s Law'),subtitle:Text('V = IR'))),Card(child:ListTile(title:Text('AC RMS'),subtitle:Text('Vrms = Vm / √2 for a sine wave'))),
Card(child:ListTile(title:Text('Resonance'),subtitle:Text('At series resonance: XL = XC and Z = R'))),Card(child:ListTile(title:Text('Nyquist'),subtitle:Text('fs ≥ 2fm'))),
Card(child:ListTile(title:Text('8085'),subtitle:Text('8-bit microprocessor; TRAP is non-maskable'))),
]);}}
