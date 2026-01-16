🚕 Tera – Taxi Queue Management System

Tera is a mobile-based taxi queue management system designed to digitalize and optimize taxi queue operations in Megenagna, Addis Ababa.
The system replaces manual queue handling with a real-time, fair, and transparent digital queue, improving efficiency for drivers and administrators.

📌 Problem Statement

In many taxi stations in Addis Ababa, queue management is handled manually, leading to:

Queue jumping and unfair service

Conflicts among drivers

Inefficient passenger flow

Lack of transparency and accountability

Tera addresses these issues by introducing a real-time digital queue system accessible via mobile devices.

🎯 Objectives

Digitize taxi queue operations

Ensure fair and transparent driver ordering

Reduce disputes among taxi drivers

Provide administrators with full queue control

Improve overall passenger service efficiency

👥 User Roles
🚖 Driver

Login using phone number (OTP authentication)

Register taxi and personal details

Join the queue digitally

View real-time queue position

Receive status updates (approved / waiting / active)

🧑‍💼 Admin

Secure admin login

Approve or reject driver registrations

Control taxi queue (next, skip, remove)

Monitor active drivers in real time

📱 Application Flow
Driver Flow
Splash Screen
   ↓
Landing Page
   ↓
Driver Login (Phone OTP)
   ↓
OTP Verification
   ↓
Driver Registration (if new)
   ↓
Waiting for Admin Approval
   ↓
Driver Home (Queue Position)

Admin Flow
Splash Screen
   ↓
Landing Page
   ↓
Admin Login
   ↓
Admin Dashboard
   ↓
Queue Management Panel

🧱 System Architecture

Frontend: Flutter (Android)

Backend: Firebase

Firebase Authentication (Phone OTP)

Cloud Firestore (real-time database)

Architecture Style: Client–Server with real-time data sync

🗄️ Database Overview (Firestore)

Collections:

drivers

uid

name

phoneNumber

plateNumber

licenseNumber

status (pending /s approved / rejected)

queuePosition

queue

driverId

timestamp

admins

email

role

🔐 Authentication

Drivers authenticate using Firebase Phone Authentication (OTP)

Admins authenticate using email & password

Role-based access enforced at application level

🧪 Testing

Unit testing for authentication logic

Integration testing with Firebase services

Manual UI testing on Android devices

Queue order validation tests

🛠️ Technologies Used

Flutter & Dart

Firebase Authentication

Cloud Firestore

Android Studio

Git & GitHub

📍 Scope Limitation

The system currently supports one taxi station (Megenagna)

Payment processing is not included

Passenger-facing mobile app is out of scope

🚀 Future Enhancements

Multi-station support

Passenger mobile app

Push notifications for queue updates

Analytics dashboard for administrators

Integration with traffic management systems

👨‍🎓 Academic Context

This project is developed as a 4th Year Software Engineering Project, focusing on:

Mobile application development

Distributed systems

Real-time databases

Software engineering best practices

📄 License

This project is for academic use. Commercial deployment requires further security, scalability, and legal considerations.
