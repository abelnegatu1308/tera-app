import 'package:flutter/material.dart';

void main() {
  try {
    Type s = Scaffold;
    print('Scaffold Type is $s');
    Type t = State<Scaffold>;
    print('ScaffoldState Type is $t');
  } catch (e) {
    print('Error: $e');
  }
}
