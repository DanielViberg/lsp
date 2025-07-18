#include <stdio.h>
#include <string.h>
#define MAX_NAME_LEN 50

typedef	struct {
	char name[MAX_NAME_LEN];
	int age;
} Person;

void greet(Person p);

int add(int a, int b);

int remove(int a, int b);

int main() {
	Person alice;
	strncpy(alice.name, "Alice", MAX_NAME_LEN);
	alice.age = 30;
	greet(alice);
	
	int result = add(5, 7);
	printf("5 + 7 = %d\n", result);
}
