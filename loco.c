#include "api_robot2.h"


/* HEADERS */
// robot functions
int detectObstacles();
void bypassingObstacles(int direction);
float distance(Vector3 position, Vector3 friendPosition);
int detectDangerLocation(Vector3 currentPosition, Vector3 dangerousLocation);
int isVisited(int index);
void printPosition(Vector3 printPosition);
void turnBaseDirection (int direction);

// utils functions
double arcSin(double x);
void itoa(int number, char* string);
float power(float x, int y);
void printInt(int number);
float squareRoot(float number);


/* global variables */
int visitedFriends[20];

/* robot functions here */

void bypassingObstacles(int direction) {
  if (detectObstacles()) {
    if (direction == 1) { // turn right
      turnBaseDirection(0);
      set_head_servo(2, 270);
    } else if (direction == 0) { // turn left
      turnBaseDirection(1);
      set_head_servo(2, 90);
    }
    while (detectObstacles()) { // move forward until you bypass the obstacle
      set_torque(30, -30); 
    }
  }
}

int detectObstacles(){
  if (get_us_distance() != -1) { // if some distance is found, then there are obstacles
    return 1;
  }

  return 0; // no obstacles
}

float distance(Vector3 position, Vector3 friendPosition) {
  float xDistance = (friendPosition.z - position.z)*(friendPosition.z - position.z);
  float yDistance = (friendPosition.x - position.x)*(friendPosition.x - position.x);

  return squareRoot(xDistance + yDistance);
}

int detectDangerLocation(Vector3 currentPosition, Vector3 dangerousLocation) {
  if ((currentPosition.x == (dangerousLocation.x - 10) || currentPosition.x == (dangerousLocation.x + 10)) && (currentPosition.z == (dangerousLocation.z - 10))) {
    turnBaseDirection(0); // turn base direction clockwise to bypass without danger
    return 1;
  } else if ( (currentPosition.x == (dangerousLocation.x - 10) || currentPosition.x == (dangerousLocation.x + 10)) && currentPosition.z == (dangerousLocation.z + 10)) {
    turnBaseDirection(1); // turn base direction counter-clockwise to bypass without danger
    return 1;
  }

  return 0; // no danger
}

// check if the friend posistion has already been visited
int isVisited(int index){
  if(visitedFriends[index] == 1)
    return 1;
  else
    return 0;
}

void printPosition(Vector3 position){
  printInt(position.x);
  puts(", ");
  printInt(position.y);
  puts(", ");
  printInt(position.z);
  puts("\n");

  return;
}

void turnBaseDirection (int direction) {
  if (direction == 1) { // direction = counter-clockwise
    set_engine_torque(1, 30); // turns the direction for walle's body
  } else if (direction == 0) { // direction = clockwise
    set_engine_torque(0, 30); // turns the direction for walle's body
  }
}

int turnIntoAngle(int angle) {
  
}

/* utils functions here */
/* ================================================================ */

void itoa(int number, char* string){
  int i = 0;
  int rem;
  int length = 0;
  int n;

  if(number == 0){
    string[0] = '0';
    string[1] = '\0';
    return;
  }
  else{
    if(number < 0){
      n = -number;
      number = -number;
    }
    else
      n = number;
  }
  
  while (n != 0){
    length++;
    n /= 10;
  }
  for (int i = 0; i < length; i++){
    rem = number % 10;
    number = number / 10;
    string[length - (i + 1)] = rem + '0';
  }
  
  string[length] = '\0';

}

float power(float x, int y) {
  if(y == 0)
    return 1;

  float result = 1;
  for (int i = 0; i < y; i++)
    result = result*x;
  
  return result;
}

void printInt(int number){
  char string[10];
  itoa(number, string);

  if(number < 0)
    puts("-");
  puts(string);
}

float squareRoot(float number) {
  float error = 0.001; //define the precision of your result
  float s = number;

  while (s - (number/s) > error) //loop until precision satisfied
    s = (s + (number/s)) / 2;
  return s;
}

// this function receives a value for a sin and it returns it's arcsin (both values are in radians)
double arcSin(double x) {
  int m = 1;
  if (x < 0) {
		x = -x;
		m = -1;
  } 
  if (x > 0 && x < 0.4) {
		return m*((0.4115/0.4)*x);
  } 
  else if (x > 0.4 && x < 0.565) {
		return m*((1.145*(x-0.4)) + 0.4115);
  }
  else if (x > 0.565 && x < 0.7004) {
		return m*((1.29689*(x-0.565)) + 0.6004);
  }
  else if (x > 0.7004 && x < 0.8014) {
		return m*((1.52*(x-0.7004)) + 0.776);
  }
  else if (x > 0.8014 && x < 0.8675) {
		return m*((1.82*(x-0.8014)) + 0.9296);
  }
  else if (x > 0.8675 && x < 0.9318) {
		return m*((2.3188*(x-0.8675)) + 1.0502);
  }
  else if (x > 0.9318 && x < 0.9758) {
		return m*((3.4340*(x-0.9318)) + 1.1993);
  }
  else if (x > 0.9758 && x < 0.995) {
		return m*((6.27*(x-0.995)) + 1.4708);
  }
  else if (x > 0.995 && x < 1) {
		return m*((20*(x-1)) + 1.57);
  }
}

int main(){
  int numOfFriends = sizeof(friends_locations) / sizeof(friends_locations[0]);
  int numOfVisitedFriends = 0;
  int currentFriendIndex;
  float minimum = 2000;
  Vector3 angles;

  Vector3 currentPosition;
  get_current_GPS_position(&currentPosition); // gets walle's current position

  Vector3 friendPosition;
  for(int i = 0; i < numOfFriends; i++){
    printInt(i);
    puts("\n"); 
    if(!isVisited(i)){
      if(distance(currentPosition, friends_locations[i]) < minimum){
        friendPosition.x = friends_locations[i].x;
        friendPosition.y = friends_locations[i].y;
        friendPosition.z = friends_locations[i].z;
        printPosition(friendPosition);
        currentFriendIndex = i;
        minimum = distance(currentPosition, friends_locations[i]);
      }
    }
  }

  int deltaX = currentPosition.x - friends_locations[currentFriendIndex].x; // calculates distance from friend at y coordinate
  int deltaZ = currentPosition.z - friends_locations[currentFriendIndex].z; // calculates distance from friend at x coordinate
  float distanceFromFriend = distance(currentPosition, friends_locations[currentFriendIndex]); // calculates distance from friend

  int resultForObtainingTheta = deltaX / distanceFromFriend;
  double theta = arcSin(resultForObtainingTheta); // angle between walle's position and friend's position
  int angGrau = (theta/3.1415)*180; // convert from radian to degrees

  if (deltaZ < 0) { 
      if (deltaX > 0) {
          angGrau = 180 - angGrau; // If walle is in the second quadrant, convert to the right degree
      } else {
          angGrau = -180 - angGrau; // If walle is in the fourth quadrant, convert to the right degree
      }
  }

  get_gyro_angles(&angles); 

  int myAngle = angles.y;
  if (myAngle > 180) { // If the unity's angle is greater than 180, then convert it to the right value in the quadrants of the Cartesian plane
    myAngle = myAngle - 360;
  }

  int angToTurnRight = myAngle - angGrau;
  int angToTurn = angToTurnRight; // Final angle to turn into friend's position
  int dirToTurn = 1; // 1 -> right / -1 -> left

  if (angToTurn > 180) {
    angToTurn = 360 - angToTurn; // If the angle to turn is greater than 180, it is better to rotate counterclockwise
    dirToTurn = -1; // turn left
  } else if (angToTurn < 0) {
    angToTurn = -angToTurn; // If the angle is a negative value, convert it to the right value
    dirToTurn = -1; // turn left
  }

  if (angToTurn >= 5) { // If the angle is correct adjusted (5 degree security rate)
    if (dirToTurn = 1) { // turn right
      set_torque(5, -5);
    } else {
      set_torque(-5, 5); // else, turn left
    }
  }

  while(currentPosition.z < (friends_locations[currentFriendIndex].z - 5)) {  // while that loops until the current position is 5 meters from the friend's position
    set_torque(15, 15);
    get_current_GPS_position(&currentPosition); // gets the current position
  }


  return 0;
}
