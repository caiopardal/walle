#include "api_robot2.h"

// robot functions
int detectObstacles();
void bypassingObstacles(int direction);
float currentDistance(Vector3 position);
void turnBaseDirection (int direction);

// utils functions
float power(float x, int y);
void reverse(char str[], int length);
float squareRoot(float number);
void itoa(int num, char* str, int base);
void swap(int *xp, int *yp);


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

float currentDistance(Vector3 position) {
  Vector3 current = {.x = 11, .y = 11, .z = 11};

  float xDistance = power(current.x - position.x, 2);
  float zDistance = power(current.z - position.z, 2);

  return squareRoot(xDistance + zDistance);
}

int detectObstacles(){
  if (get_us_distance() != -1) { // if some distance is found, then there are obstacles
    return 1;
  }

  return 0; // no obstacles
}

void turnBaseDirection (int direction) {
  if (direction == 1) { // direction = counter-clockwise
    set_engine_torque(1, 30); // turns the direction for walle's body
  } else if (direction == 0) { // direction = clockwise
    set_engine_torque(0, 30); // turns the direction for walle's body
  }
}

/* ultis functions here */
 
// Implementation of itoa() 
void itoa(int num, char* str, int base) { 
	int i = 0; 
	int isNegative = 0; 

	/* Handle 0 explicitely, otherwise empty string is printed for 0 */
	if (num == 0) { 
		str[i++] = '0'; 
		str[i] = '\0'; 
		return str; 
	} 

	// In standard itoa(), negative numbers are handled only with 
	// base 10. Otherwise numbers are considered unsigned. 
	if (num < 0 && base == 10) { 
		isNegative = 1; 
		num = -num; 
	} 

	// Process individual digits 
	while (num != 0) { 
		int rem = num % base; 
		str[i++] = (rem > 9)? (rem-10) + 'a' : rem + '0'; 
		num = num/base; 
	} 

	// If number is negative, append '-' 
	if (isNegative) 
		str[i++] = '-'; 

	str[i] = '\0'; // Append string terminator 

	// Reverse the string 
	reverse(str, i); 

	return; 
} 


float power(float x, int y) {
  if(y == 0)
    return 1;

  float result = 1;
  for (int i = 0; i < y; i++)
    result = result*x;
  
  return result;
}

/* A utility function to reverse a string */
void reverse(char str[], int length) { 
	int start = 0; 
	int end = length -1; 
	while (start < end) { 
		swap(*(str+start), *(str+end)); 
		start++; 
		end--; 
	} 
} 

float squareRoot(float number) {
  float error = 0.00001; //define the precision of your result
  float s = number;

  while (s - (number/s) > error) //loop until precision satisfied 
  {
      s = (s + (number/s)) / 2;
  }
  return s;
}

void swap(int *xp, int *yp) { 
    int temp = *xp; 
    *xp = *yp; 
    *yp = temp; 
} 


int main(){
  set_head_servo(0, 60);
  set_head_servo(1, 60);

  return 0;
}
