import 'package:doctor_app/appointmentConfirmation.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class BookAppointment extends StatefulWidget {
  var DocName,docspecialist,docPic,Rating,fee;
 BookAppointment({super.key,
  required this.DocName,
  required this.docspecialist,
  required this.Rating,
  required this.docPic,
  required this.fee});


  @override
  State<BookAppointment> createState() => _BookAppointmentState();
}

class _BookAppointmentState extends State<BookAppointment> {
  DateTime focusedDay = DateTime.now();
  DateTime selectedDay = DateTime.now();

  int selectedTime = 2;

  List<String> times = [
    "09.00 AM",
    "09.30 AM",
    "10.00 AM",
    "10.30 AM",
    "11.00 AM",
    "11.30 AM",
    "03.00 PM",
    "03.30 PM",
    "04.00 PM",
    "04.30 PM",
    "05.00 PM",
    "05.30 PM",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Book Appointment"),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            const Text(
              "Select Date",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 15),

            Card(
              color: const Color(0xffEEF3FF),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: TableCalendar(
                  firstDay: DateTime.utc(2024),
                  lastDay: DateTime.utc(2035),
                  focusedDay: focusedDay,

                  selectedDayPredicate: (day) {
                    return isSameDay(selectedDay, day);
                  },

                  onDaySelected: (selected, focused) {
                    setState(() {
                      selectedDay = selected;
                      focusedDay = focused;
                    });
                  },

                  headerStyle: const HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: false,
                  ),

                  calendarStyle: CalendarStyle(
                    todayDecoration: BoxDecoration(
                      color: Colors.blue.shade200,
                      shape: BoxShape.circle,
                    ),
                    selectedDecoration: const BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 25),

            const Text(
              "Select Hour",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 15),

            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: List.generate(times.length, (index) {
                bool selected = selectedTime == index;

                return InkWell(
                  onTap: () {
                    setState(() {
                      selectedTime = index;
                    });
                  },
                  child: Container(
                    width: 105,
                    height: 45,
                    decoration: BoxDecoration(
                      color: selected
                          ? Colors.blue
                          : Colors.white,
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(
                        color: Colors.blue,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        times[index],
                        style: TextStyle(
                          color: selected
                              ? Colors.white
                              : Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),

      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            height: 55,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              onPressed: () {

            
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => Appointmentconfirmation(
        selectedDay:
            "${selectedDay.day}/${selectedDay.month}/${selectedDay.year}",

        selectedTime: times[selectedTime], // Time String

        DocName: widget.DocName,

        docspecialist: widget.docspecialist,

        docPic: widget.docPic,

        Rating: widget.Rating,
        fee: widget.fee,
      ),
    ),
  );

                       }  
                       ,
                       
                              child: const Text(
                "Next",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}