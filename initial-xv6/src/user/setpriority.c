#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"
#include "kernel/fcntl.h"

int main(int argc, char* argv[])
{
     if (argc < 3) {
        printf("Usage: %s argument1 argument2 ... argumentN\n", argv[0]);
        return 1;  // Exit the program with an error code
    }

    int priority1 = atoi(argv[1]);
    int priority2 = atoi(argv[2]);

    set_priority(priority1,priority2);
    return 0;
}