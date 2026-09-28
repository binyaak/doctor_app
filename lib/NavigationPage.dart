import 'package:doctor_app/Appointment.dart';
import 'package:doctor_app/DoctorDetail.dart';
import 'package:doctor_app/Favourites.dart';
import 'package:doctor_app/ProfilePage.dart';
//import 'package:doctor_app/dd.dart';
import 'package:doctor_app/homePage.dart';
import 'package:flutter/material.dart';

class Navigationpage extends StatefulWidget {
  const Navigationpage({super.key});

  @override
  State<Navigationpage> createState() => _NavigationpageState();
}

class _NavigationpageState extends State<Navigationpage> {

   var initilalIndex = 0;  

   List<Widget> get docTabItems => [
     const HomePage(),
     const AppointmentPage(),
     const Favourites(),
     const ProfilePage(),
   ];


  @override
  Widget build(BuildContext context) {
    return Scaffold(

  /* appBar: AppBar(
          backgroundColor: Colors.transparent,
        //   scrolledUnderElevation: 0,
        //  centerTitle: true,
    //    backgroundColor: Colors.black,
        leading: const Icon(Icons.menu, color: Color.fromARGB(255, 15, 15, 15)),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
         // crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              height: 35,width: 35,
              child: Image.asset('asset/logo.jpg')),
             Text(" Doctor App", style: TextStyle(fontWeight: FontWeight.bold,color: Color.fromARGB(255, 12, 103, 177)),),
          ],
        ),                                
        actions: const [Icon(Icons.notifications, color: Color.fromARGB(255, 15, 15, 15))],
      ),*/


     bottomNavigationBar:BottomNavigationBar(items: [
      BottomNavigationBarItem(icon: Icon(Icons.home),
      label: "Home"),

      BottomNavigationBarItem(icon: Icon(Icons.calendar_view_month_outlined),
      label: "Appoinments"),
      BottomNavigationBarItem(icon: Icon(Icons.favorite),
     label:  'Favorites'),
     BottomNavigationBarItem(icon: Icon(Icons.person),
     label: 'Profile')

     ],
     
     currentIndex: initilalIndex,
     selectedItemColor: Colors.blueAccent,
    unselectedItemColor: const Color.fromARGB(255, 158, 157, 157),
     iconSize: 30,
     onTap:(int index) {
      setState(() {
        initilalIndex=index;
      });
       
     },

     ) ,

     body: docTabItems[initilalIndex],
     




     


    );
  }
}