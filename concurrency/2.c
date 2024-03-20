#include <stdio.h>
#include <stdlib.h>
#include <pthread.h>
#include <unistd.h>
#include "limits.h"
#include "string.h"
#include "semaphore.h"
#include "time.h"

#define ANSI_COLOR_WHITE "\x1b[37m"
#define ANSI_COLOR_YELLOW "\x1b[33m"
#define ANSI_COLOR_CYAN "\x1b[36m"
#define ANSI_COLOR_BLUE "\x1b[34m"
#define ANSI_COLOR_GREEN "\x1b[32m"
#define ANSI_COLOR_RED "\x1b[31m"
#define ANSI_COLOR_ORANGE "\x1b[33m"

// ANSI escape code for resetting text color
#define ANSI_COLOR_RESET "\x1b[0m"

// Define constants
#define MAX_MACHINES 10
#define MAX_FLAVORS 10
#define MAX_TOPPINGS 10
#define MAX_CUSTOMERS 100
#define MAX_ORDERS 100

// Struct to represent an ice cream machine
typedef struct
{
    int id;
    int start_time;
    int end_time;
    pthread_t thread;
    int available;
} Machine;

// Struct to represent an ice cream flavor
typedef struct
{
    char name[50];
    int preparation_time;
    int ingredient_quantity;
} Flavor;

// Struct to represent a topping
typedef struct
{
    char name[50];
    int preparation_time;
    int quantity;
} Topping;

typedef struct
{
    char flavor[150]; // An array of strings to store flavor names
    char toppings[MAX_TOPPINGS][150];
    int num_toppings;
    int started;
    int done;
} Order;
// Struct to represent a customer's order
typedef struct
{
    int id;
    int arrival_time;
    int num_ice_creams;
    int done;
    int left;
    Order order[MAX_ORDERS];

} CustomerOrder;

// Global variables
int N, K, F, T;
int num_machines, max_customers, num_flavors, num_toppings, num_customers;
Machine machines[MAX_MACHINES];
Flavor flavors[MAX_FLAVORS];
Topping toppings[MAX_TOPPINGS];
CustomerOrder orders[MAX_CUSTOMERS];
pthread_mutex_t mutex = PTHREAD_MUTEX_INITIALIZER;
sem_t machine_available[MAX_MACHINES];
int served_customers = 0;
int curr_time = 0;
int elapsedSeconds;
time_t startTime, currentTime;
int curr_queue = 0;
int cust_done[MAX_CUSTOMERS];
int count_left = 0;

void *print_machine(void *m_id)
{
    int machine_id = *(int *)m_id;

    // printf("#%d %d#\n", machines[machine_id].start_time, machines[machine_id].end_time);
    // if (machines[machine_id].start_time != 0)
    // {
    pthread_mutex_lock(&mutex);
    time(&currentTime);
    elapsedSeconds = difftime(currentTime, startTime);
    pthread_mutex_unlock(&mutex);
    // printf("*%d*\n", elapsedSeconds);
    while (elapsedSeconds < machines[machine_id].start_time)
    {
        pthread_mutex_lock(&mutex);
        time(&currentTime);
        elapsedSeconds = difftime(currentTime, startTime);
        pthread_mutex_unlock(&mutex);
        // printf("*%d*\n", elapsedSeconds);
        sleep(0.01);
    }
    //}
    // sleep(machines[machine_id].start_time-elapsedSeconds);
    if (elapsedSeconds >= machines[machine_id].start_time)
    {
        printf("\e[38;2;255;85;0m");
        printf("Machine %d has started working at %d second(s)\n", machine_id + 1, machines[machine_id].start_time);
        printf("\e[0m");
        machines[machine_id].available = 1;
    }
    machines[machine_id].available = 1;

    pthread_mutex_lock(&mutex);
    time(&currentTime);
    elapsedSeconds = difftime(currentTime, startTime);
    pthread_mutex_unlock(&mutex);
    // printf("*%d*\n", elapsedSeconds);
    while (elapsedSeconds < machines[machine_id].end_time)
    {
        pthread_mutex_lock(&mutex);
        time(&currentTime);
        elapsedSeconds = difftime(currentTime, startTime);
        pthread_mutex_unlock(&mutex);
        //  printf("*%d*\n", elapsedSeconds);
        sleep(0.01);
    }
    // sleep(machines[machine_id].end_time-elapsedSeconds);
    if (elapsedSeconds >= machines[machine_id].end_time)
    {
        printf("\e[38;2;255;85;0m");
        printf("Machine %d has stopped working at %d second(s)\n", machine_id + 1, machines[machine_id].end_time);
        printf("\e[0m");
        machines[machine_id].available = 0;
    }
    machines[machine_id].available = 0;
    return 0;
}

void *make_order(void *arg)
{
    int *arr = (int *)arg;
    int cust_id = arr[0];
    int order_no = arr[1];
    if (order_no != 0)
    {
        while (orders[cust_id].order[order_no - 1].started != 1)
            sleep(0.01);
    }
    if (orders[cust_id].left == 1)
    {
        orders[cust_id].order[order_no].started == 1;
        cust_done[cust_id] = 1;
        curr_queue--;
        return 0;
    }
    while (orders[cust_id].order[order_no].started == 0)
    {
        int stopp_flag = 0;
        for (int i = 0; i < N; i++)
        {
            if (machines[i].available == 1)
            {
                stopp_flag = 1;
                break;
            }
            pthread_mutex_lock(&mutex);
            time(&currentTime);
            elapsedSeconds = difftime(currentTime, startTime);
            if (machines[i].end_time > elapsedSeconds)
            {
                stopp_flag = 1;
                pthread_mutex_unlock(&mutex);
                break;
            }
            else
                pthread_mutex_unlock(&mutex);
        }
        if (stopp_flag == 0)
        {
            pthread_mutex_lock(&mutex);
            orders[cust_id].order[order_no].started = 1;
            if (orders[cust_id].left == 0)
            {
                printf(ANSI_COLOR_RED "Customer %d was not serviced due to unavailability of machines\n" ANSI_COLOR_RESET, cust_id + 1);
                orders[cust_id].left = 1;
                cust_done[cust_id] = 1;
                curr_queue--;
            }
            pthread_mutex_unlock(&mutex);
            break;
        }
        int preparation_time = -1;
        for (int i = 0; i < F; i++)
        {
            if (strcmp(flavors[i].name, orders[cust_id].order[order_no].flavor) == 0)
            {
                preparation_time = flavors[i].preparation_time;
                break;
            }
        }
        // printf("*%d*\n",cust_id+1);
        if (preparation_time == -1)
        {
            printf("INVALID ORDER");
            break;
        }
        for (int j = 0; j < orders[cust_id].order[order_no].num_toppings; j++)
        {
            for (int i = 0; i < T; i++)
            {
                if (strcmp(toppings[i].name, orders[cust_id].order[order_no].toppings[j]) == 0)
                {
                    if (toppings[i].quantity <= 0)
                    {
                        pthread_mutex_lock(&mutex);
                        time(&currentTime);
                        elapsedSeconds = difftime(currentTime, startTime);
                        if (orders[cust_id].left == 0)
                        {
                            printf(ANSI_COLOR_RED "Customer %d left at %d second(s) with an unfulfilled order\n" ANSI_COLOR_RESET, cust_id + 1, elapsedSeconds);
                            orders[cust_id].left = 1;
                            cust_done[cust_id] = 1;
                            curr_queue--;
                        }
                        orders[cust_id].order[order_no].started = 1;
                        pthread_mutex_unlock(&mutex);
                        return 0;
                    }
                    break;
                }
            }
        }
        // if (stopp_flag == 0)
        // {
        //     pthread_mutex_lock(&mutex);
        //     orders[cust_id].order[order_no].started = 1;
        //     if (orders[cust_id].left == 0)
        //     {
        //         printf(ANSI_COLOR_RED "Customer %d was not serviced due to unavailability of machines\n" ANSI_COLOR_RESET, cust_id + 1);
        //         orders[cust_id].left = 1;
        //         cust_done[cust_id] = 1;
        //         curr_queue--;
        //     }
        //     pthread_mutex_unlock(&mutex);
        //     return 0;
        //     break;
        // }
        int selected = -1;
        int break_flag = 0;
        while (selected == -1)
        {
            int available_count = 0;
            for (int i = 0; i < N; i++)
            {
                // sleep(0.01);

                pthread_mutex_lock(&mutex);
                time(&currentTime);
                elapsedSeconds = difftime(currentTime, startTime);
                if (machines[i].end_time > elapsedSeconds)
                {
                    available_count = 1;
                }
                pthread_mutex_unlock(&mutex);
                if (machines[i].available == 1)
                    available_count = 1;
                if (sem_trywait(&machine_available[i]) != 0)
                    continue;
                else
                {
                    pthread_mutex_lock(&mutex);
                    time(&currentTime);
                    elapsedSeconds = difftime(currentTime, startTime);
                    int total_prep = preparation_time + elapsedSeconds;
                    pthread_mutex_unlock(&mutex);
                    if (machines[i].available == 0 || machines[i].end_time <= total_prep) //if machine ends at same time order ends, won't accept
                    {
                        sem_post(&machine_available[i]);
                        continue;
                    }
                    selected = i;
                    break;
                }
            }

            if (available_count == 0)
            {
                pthread_mutex_lock(&mutex);
                orders[cust_id].order[order_no].started = 1;
                if (orders[cust_id].left == 0)
                {
                    printf(ANSI_COLOR_RED "Customer %d was not serviced due to unavailability of machines\n" ANSI_COLOR_RESET, cust_id + 1);
                    orders[cust_id].left = 1;
                    cust_done[cust_id] = 1;
                    curr_queue--;
                }
                break_flag = 1;
                pthread_mutex_unlock(&mutex);
                break;
            }
        }

        if (break_flag == 1)
            break;
        pthread_mutex_lock(&mutex);
        for (int j = 0; j < orders[cust_id].order[order_no].num_toppings; j++)
        {
            for (int i = 0; i < T; i++)
            {
                if (strcmp(toppings[i].name, orders[cust_id].order[order_no].toppings[j]) == 0)
                {
                    // printf("%s %d %d\n",toppings[i].name,toppings[i].quantity,cust_id);
                    if (toppings[i].quantity <= 0)
                    {
                        pthread_mutex_lock(&mutex);
                        time(&currentTime);
                        elapsedSeconds = difftime(currentTime, startTime);
                        if (orders[cust_id].left == 0)
                        {
                            printf(ANSI_COLOR_RED "Customer %d left at %d second(s) with an unfulfilled order\n" ANSI_COLOR_RESET, cust_id + 1, elapsedSeconds);
                            orders[cust_id].left = 1;
                            cust_done[cust_id] = 1;
                            curr_queue--;
                        }
                        orders[cust_id].order[order_no].started = 1;
                        sem_post(&machine_available[selected]);
                        pthread_mutex_unlock(&mutex);
                        return 0;
                    }
                    // Customer c left at t second(s) with an unfulfilled order
                    // else
                    //     toppings[i].quantity--;
                    break;
                }
            }
        }
        time(&currentTime);
        elapsedSeconds = difftime(currentTime, startTime);
        printf(ANSI_COLOR_CYAN "Machine %d starts preparing ice cream %d of Customer %d at %d second(s)\n" ANSI_COLOR_RESET, selected + 1, order_no + 1, cust_id + 1, elapsedSeconds);
        orders[cust_id].order[order_no].started = 1;
        pthread_mutex_unlock(&mutex);
        // printf("!! %d\n",preparation_time);
        for (int i = 0; i < preparation_time; i++)
        {
            if (machines[selected].available == 0)
            {
                sem_post(&machine_available[selected]);
                orders[cust_id].order[order_no].started = 0;
                continue;
            }
            sleep(1);
        }
        // finish_times[selected] = preparation_finish_time;
        pthread_mutex_lock(&mutex);
        time(&currentTime);
        elapsedSeconds = difftime(currentTime, startTime);
        if (machines[selected].available == 0)
        {
            sem_post(&machine_available[selected]);
            orders[cust_id].order[order_no].started = 0;
            pthread_mutex_unlock(&mutex);
            continue;
        }
        for (int j = 0; j < orders[cust_id].order[order_no].num_toppings; j++)
        {
            for (int i = 0; i < T; i++)
            {
                if (strcmp(toppings[i].name, orders[cust_id].order[order_no].toppings[j]) == 0)
                {
                    if (toppings[i].quantity <= 0)
                    {
                        pthread_mutex_lock(&mutex);
                        time(&currentTime);
                        elapsedSeconds = difftime(currentTime, startTime);
                        if (orders[cust_id].left == 0)
                        {
                            printf(ANSI_COLOR_RED "Customer %d left at %d second(s) with an unfulfilled order\n" ANSI_COLOR_RESET, cust_id + 1, elapsedSeconds);
                            orders[cust_id].left = 1;
                            cust_done[cust_id] = 1;
                            curr_queue--;
                        }
                        orders[cust_id].order[order_no].started = 1;
                        sem_post(&machine_available[selected]);
                        pthread_mutex_unlock(&mutex);
                        return 0;
                    }
                    break;
                }
            }
        }
        printf(ANSI_COLOR_BLUE "Machine %d completes preparing ice cream %d of Customer %d at %d second(s)\n", selected + 1, order_no + 1, cust_id + 1, elapsedSeconds);
        orders[cust_id].order[order_no].done = 1;
        pthread_mutex_unlock(&mutex);
        for (int j = 0; j < orders[cust_id].order[order_no].num_toppings; j++)
        {
            for (int i = 0; i < T; i++)
            {
                if (strcmp(toppings[i].name, orders[cust_id].order[order_no].toppings[j]) == 0)
                {
                    //  printf("%s %d",toppings[i].name,toppings[i].quantity);
                    toppings[i].quantity--; // only waste ingredients when order is completed
                    // if (toppings[i].quantity == 0)
                    // {
                    //     for (int m = 0; m < num_customers; m++)
                    //     {
                    //         if(m==cust_id)
                    //         continue;
                    //         for (int k = 0; k < orders[m].num_ice_creams; k++)
                    //         {
                    //             for (int t = 0; t < orders[m].order[k].num_toppings; t++)
                    //             {
                    //                 if (strcmp(toppings[i].name, orders[m].order[k].toppings[t]) == 0)
                    //                 {
                    //                     pthread_mutex_lock(&mutex);
                    //                     time(&currentTime);
                    //                     elapsedSeconds = difftime(currentTime, startTime);
                    //                     //printf("*%d %d %s",m, cust_id+1,toppings[i].name);
                    //                     if (orders[cust_id].left == 0)
                    //                     {
                    //                         printf(ANSI_COLOR_RED "Customer %d left at %d second(s) with an unfulfilled order\n" ANSI_COLOR_RESET, m + 1, elapsedSeconds);
                    //                         orders[m].left = 1;
                    //                         cust_done[m] = 1;
                    //                         curr_queue--;
                    //                     }
                    //                     orders[m].order[order_no].started = 1;
                    //                     pthread_mutex_unlock(&mutex);
                    //                 }
                    //             }
                    //         }
                    //     }
                    // }
                    break;
                }
            }
        }
        sem_post(&machine_available[selected]);
    }
    return NULL;
}

void *serve_customer(void *arg)
{
    while (served_customers < num_customers)
    {

        pthread_mutex_lock(&mutex);
        int customer_id = served_customers;
        served_customers++;
        if (curr_queue > K)
        {
            curr_queue--;
            cust_done[customer_id] = 1;
            orders[customer_id].left = 1;
            pthread_mutex_unlock(&mutex);
            return 0;
        }
        curr_queue++;
        pthread_mutex_unlock(&mutex);

        if (customer_id >= num_customers)
        {
            break;
        }

        int arrival_time = orders[customer_id].arrival_time;
        int num_orders = orders[customer_id].num_ice_creams;
        pthread_mutex_lock(&mutex);
        time(&currentTime);
        elapsedSeconds = difftime(currentTime, startTime);
        pthread_mutex_unlock(&mutex);
        while (elapsedSeconds < arrival_time)
        {
            pthread_mutex_lock(&mutex);
            time(&currentTime);
            elapsedSeconds = difftime(currentTime, startTime);
            pthread_mutex_unlock(&mutex);
            // printf("*%d*\n", elapsedSeconds);
            sleep(0.01);
        }
        // printf("*%d",customer_id);
        if (elapsedSeconds >= arrival_time)
        {
            pthread_mutex_lock(&mutex);
            printf(ANSI_COLOR_WHITE "Customer %d enters at %d second(s)\n" ANSI_COLOR_RESET, customer_id + 1, arrival_time);
            printf(ANSI_COLOR_YELLOW "Customer %d orders %d ice creams\n" ANSI_COLOR_RESET, customer_id + 1, num_orders);
            for (int i = 0; i < num_orders; i++)
            {
                printf(ANSI_COLOR_YELLOW "Ice Cream %d: %s ", i + 1, orders[customer_id].order[i].flavor);
                for (int j = 0; j < orders[customer_id].order[i].num_toppings; j++)
                {
                    printf(ANSI_COLOR_YELLOW "%s ", orders[customer_id].order[i].toppings[j]);
                }
                printf("\n" ANSI_COLOR_RESET);
            }
            pthread_mutex_unlock(&mutex);
        }
        if (customer_id != 0)
        {
            while (cust_done[customer_id - 1] == 0)
                {sleep(0.01);
                    if(orders[customer_id].left==1 || orders[customer_id].done==1)
                    {
                        orders[customer_id].left=1;
                        orders[customer_id].done=1;
                        return 0;
                    }
                }
        }

        pthread_t order_threads[num_orders];
        sleep(1);
        for (int i = 0; i < num_orders; i++)
        {
            int *arr = (int *)malloc(sizeof(int) * 2);
            arr[0] = customer_id;
            arr[1] = i;
            int *c_id = malloc(sizeof(int)); // Allocate memory for c_id
            if (c_id == NULL)
            {
                exit(1);
            }
            *c_id = i;
            pthread_create(&order_threads[i], NULL, make_order, arr);
        }
        for (int i = 0; i < num_orders; i++)
        {

            pthread_join(order_threads[i], NULL);
        }

        int done_flag = 1;
        for (int i = 0; i < num_orders; i++)
        {
            if (orders[customer_id].order[i].done == 0)
            {
                done_flag = 0;
                break;
            }
        }
        if (done_flag)
        {
            pthread_mutex_lock(&mutex);
            time(&currentTime);
            elapsedSeconds = difftime(currentTime, startTime);
            printf(ANSI_COLOR_GREEN "Customer %d has collected their order(s) and left at %d second(s)\n", customer_id + 1, elapsedSeconds);
            orders[customer_id].left = 1;
            cust_done[customer_id] = 1;
            curr_queue--;
            pthread_mutex_unlock(&mutex);
        }
    }
    return NULL;
}

int main()
{
    // int N, K, F, T;
    scanf("%d %d %d %d", &N, &K, &F, &T);
    int mach_end = 0;
    // Parse machine timings
    for (int i = 0; i < N; i++)
    {
        scanf("%d %d", &machines[i].start_time, &machines[i].end_time);
        machines[i].id = i;
        machines[i].available = 0;
        if (machines[i].end_time > mach_end)
            mach_end = machines[i].end_time;
    }
    // Parse ice cream flavors
    for (int i = 0; i < F; i++)
    {
        scanf("%s %d", flavors[i].name, &flavors[i].preparation_time);
    }

    // Parse toppings
    for (int i = 0; i < T; i++)
    {
        scanf("%s %d", toppings[i].name, &toppings[i].quantity);
        if (toppings[i].quantity == -1)
            toppings[i].quantity = INT_MAX;
    }

    // Initialize data structures to track machine availability, toppings, and customer queue

    int toppings_available[T];
    for (int i = 0; i < T; i++)
    {
        toppings_available[i] = toppings[i].quantity;
    }

    CustomerOrder queue[K]; // Assume a maximum of K customers can wait in the queue
    int queue_length = 0;

    int customers_served = 0;
    int customers_rejected = 0;
    num_customers = 0; // Track the number of customers
    char c = getchar();
    while (1)
    {
        int c, t_arr, id;
        char *s = (char *)malloc(sizeof(char) * 25);
        if (fgets(s, sizeof(s), stdin) == NULL)
        {
            break;
        }

        // Remove the trailing newline character, if any
        size_t len = strlen(s);
        if (len > 0 && s[len - 1] == '\n')
        {
            s[len - 1] = '\0';
        }

        if (sscanf(s, "%d %d %d", &id, &t_arr, &c) != 3)
        {
            break;
        }
        orders[num_customers].id = num_customers;
        orders[num_customers].num_ice_creams = c;
        orders[num_customers].arrival_time = t_arr;
        orders[num_customers].left = 0;

        for (int j = 0; j < c; j++)
        {
            char order[1024];
            scanf(" %[^\n]", order);
            const char delimiters[] = " \n";
            char *word = (char *)malloc(sizeof(char) * 1024);

            word = strtok(order, delimiters); // Get the first word
            int count = 0;
            while (word != NULL)
            {
                // Process the word (e.g., print it)
                if (count == 0)
                    strcpy(orders[num_customers].order[j].flavor, word);
                else
                    strcpy(orders[num_customers].order[j].toppings[count - 1], word);
                count++;
                word = strtok(NULL, delimiters);
            }
            orders[num_customers].order[j].num_toppings = count - 1;
            orders[num_customers].order[j].started = 0;
            orders[num_customers].order[j].done = 0;
        }
        c = getchar();
        // printf("Fone");
        cust_done[num_customers] = 0;
        num_customers++;
        // printf("%d %d",num_customers,K);
    }

    for (int i = 0; i < N; i++)
    {
        sem_init(&machine_available[i], 0, 1);
        // int value;
        // sem_getvalue(&machine_available[i], &value);
        // printf("%d ",value);
        // pthread_create(&machines[i].thread, NULL, machine_work, &machines[i]);
    }
    pthread_t customer_threads[num_customers];
    pthread_t machine_threads[num_machines];
    // Simulate customer orders and machine operations
    // ...
    time(&startTime);

    int count_cust = 0;
    for (int i = 0; i < N; i++)
    {
        int *c_id = malloc(sizeof(int)); // Allocate memory for c_id
        if (c_id == NULL)
        {
            exit(1);
        }
        *c_id = i;
        pthread_create(&machine_threads[i], NULL, print_machine, c_id);

        if (count_cust < num_customers)
        {
            int *c_id2 = malloc(sizeof(int)); // Allocate memory for c_id
            if (c_id2 == NULL)
            {
                exit(1);
            }
            *c_id2 = count_cust;
            pthread_create(&customer_threads[i], NULL, serve_customer, c_id2);
            count_cust++;
        }
    }
    for (int i = count_cust; i < num_customers; i++)
    {
        int *c_id = malloc(sizeof(int)); // Allocate memory for c_id
        if (c_id == NULL)
        {
            exit(1);
        }
        *c_id = i;
        pthread_create(&customer_threads[i], NULL, serve_customer, c_id);
    }
    time(&currentTime);
    elapsedSeconds = difftime(currentTime, startTime);
    sleep(mach_end - elapsedSeconds);

    for (int i = 0; i < N; i++)
    {
        pthread_join(machine_threads[i], NULL);
    }
    for (int i = 0; i < num_customers; i++)
    {
        pthread_join(customer_threads[i], NULL);
    }

    for (int i = 0; i < N; i++)
    {
        sem_destroy(&machine_available[i]);
    }
    printf("Parlor Closed\n");
    // printf("%d Customers were sent away due to limited resources\n",count_left);
    return 0;
}
