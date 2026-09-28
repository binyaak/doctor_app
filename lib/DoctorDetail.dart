import 'package:doctor_app/bookAppointment.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class Doctordetail extends StatefulWidget {
  var doctor;//docPic,Rating;
   Doctordetail({super.key,
   required this.doctor,
  
   });

  @override
  State<Doctordetail> createState() => _DoctordetailState();
}

class _DoctordetailState extends State<Doctordetail> {

  bool isExpanded = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: AppBar(
        automaticallyImplyLeading: false,
       // leading: Icon(Icons.arrow_back,color: const Color.fromARGB(255, 82, 81, 81),),
     //   title: Text("Doc Name"),
        toolbarHeight: 300,
        backgroundColor:Colors.transparent,
          flexibleSpace: Stack(
            
            
            children: [

             Align(
  alignment: Alignment.bottomCenter,
  child: Image.asset(
widget.doctor['docPic'],
    height: 260,
    fit: BoxFit.contain,
  ),
),
            Container(
              width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                     
            Colors.transparent,
             Color.fromARGB(12, 28, 98, 189),
             Color.fromARGB(36, 28, 98, 189),
            
            Color.fromARGB(83, 28, 98, 189),
               Color.fromARGB(115, 33, 149, 243)
            
                    ],
                    
                  // stops: [0.1, 1.0], 
                  ),
                  
               borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                  
                ),
                child: 
                InkWell(
                  onTap: () => setState(() {
                    Navigator.pop(context);

                  }),                  
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      
                      children: [
                       Container(
                              decoration: BoxDecoration(
                               shape:BoxShape.circle ,
                               border: Border.all(color: Colors.black12)
                               //RoundedRectangleBorder()
                  
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Icon(Icons.arrow_back),
                              ),
                       ),
                       Padding(
                               padding: const EdgeInsets.all(8.0),
                               child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                 SizedBox(
                  width: 70,
                   child: Card(
                     elevation: 3,
                    shadowColor: Colors.black12,
                               
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.star,color: CupertinoColors.systemYellow,size: 10,),
                        Text(widget.doctor["Rating"],style: TextStyle(fontWeight: FontWeight.bold),)
                       
                      ],
                    ),
                       
                    
                   ),
                                 ),
                                 Text(widget.doctor["DocName"],style: TextStyle(color: Colors.white,fontSize: 25,fontWeight: FontWeight.bold),),
                                 Text(widget.doctor["specialist"],style: TextStyle(color: Colors.white,fontSize: 15),)
                                ],
                               ),
                       )
                      ],
                    ),
                  ),
                ),
            
                
              ),]
          ),
        
      ),
      backgroundColor: const Color.fromARGB(123, 230, 228, 228),
      body: 
      
      SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SizedBox(
                    height: 100,
                    width: 100,
                    child: Card(
                      color: Colors.white,
                      child: 
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(widget.doctor['experience'],style: TextStyle(fontSize: 23,
                          fontWeight: FontWeight.bold,color: const Color.fromARGB(220, 32, 32, 32)),),
                          Text("Rating",style: TextStyle(fontSize: 14,
                         
                          color: const Color.fromARGB(197, 92, 92, 92)))
                        ],
                      ),
                    ),
                  ),
                  
                    SizedBox(
                    height: 100,
                    width: 120,
                    child: Card(
                      color: Colors.white,
                      child: 
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text("6 Years",style: TextStyle(fontSize: 23,
                          fontWeight: FontWeight.bold,color: const Color.fromARGB(220, 32, 32, 32)),),
                          Text("Experience",style: TextStyle(fontSize: 14,
                         
                          color: const Color.fromARGB(197, 92, 92, 92)))
                        ],
                      ),
                    ),
                  ),
                    SizedBox(
                    height: 100,
                    width: 100,
                    child: Card(
                      color: Colors.white,
                      child: 
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text("255",style: TextStyle(fontSize: 23,
                          fontWeight: FontWeight.bold,color: const Color.fromARGB(220, 32, 32, 32)),),
                          Text("Reviews",style: TextStyle(fontSize: 14,
                         
                          color: const Color.fromARGB(197, 92, 92, 92)))
                        ],
                      ),
                    ),
                  ),
                  
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Card(
                color: Colors.white,
                child: 
                Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text("About",style: TextStyle(fontSize: 18,fontWeight:FontWeight.bold),),
                          ),
                          
                          
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text("View All",
                            style: TextStyle(color: Colors.blue)
                            ,
                            
                            ),
                          )
                      
                        ],
                      ),
                    ),
                  Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
              Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        "Dr. Alan Smith is a compassionate and experienced Pediatric Cardiologist dedicated to providing comprehensive healthcare for infants, children, and adolescents. With over 10 years of clinical experience, he specializes in diagnosing and treating congenital and acquired heart conditions in children. Dr. Smith is committed to delivering personalized, evidence-based care while ensuring every young patient and their family feels comfortable, informed, and supported throughout the treatment journey. He believes in combining advanced medical expertise with a caring approach to achieve the best possible outcomes for every child.",
                        style: TextStyle(color:  const Color.fromARGB(197, 92, 92, 92))
                       ,
                         maxLines: isExpanded ? null : 4,
                        overflow: isExpanded
                ? TextOverflow.visible
                : TextOverflow.ellipsis,
                      ),
              ),
                      
              GestureDetector(
                      onTap: () {
                        setState(() {
              isExpanded = !isExpanded;
                        });
                      },
                      child: Text(
                        isExpanded ? "Read Less" : "Read More",
                        style: TextStyle(
              color: Colors.blue,
              fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
                        ],
                      ),
                   
                  ],
                ),
              ),
            ),
        
          Padding(
  padding: const EdgeInsets.all(8.0),
  child: Card(
    color: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          const Text(
            "Working Hours",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 15),

          Row(
            children: const [
              Icon(Icons.calendar_today,
                  color: Colors.blue, size: 20),
              SizedBox(width: 10),
              Text(
                "Monday - Friday",
                style: TextStyle(fontSize: 15),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: const [
              Icon(Icons.access_time,
                  color: Colors.blue, size: 20),
              SizedBox(width: 10),
              Text(
                "09:00 AM - 05:00 PM",
                style: TextStyle(fontSize: 15),
              ),
            ],
          ),

          const Divider(height: 30),

          Row(
            children: const [
              Icon(Icons.event_available,
                  color: Colors.green, size: 20),
              SizedBox(width: 10),
              Text(
                "Available Today",
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  ),
),
                  
         
          ],
        ),
      ),
        bottomNavigationBar: SafeArea(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        height: 55,
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: () {

            Navigator.push(context, MaterialPageRoute(builder: (context)=>BookAppointment(
              DocName: widget.doctor["DocName"], docspecialist: widget.doctor["specialist"],
              
              docPic: widget.doctor["docPic"],Rating: widget.doctor['Rating'],
              fee: widget.doctor["fee"],)));
          },
          child: const Text(
            "Book Appointment",
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
        ),),),),
      
    );
  }
}