#include <stdio.h>
#include <stdlib.h>
#include <pthread.h>
#include <semaphore.h>
#include <string.h>
#include <unistd.h>
#include <time.h>

#define MAX_CUSTOMERS 100
#define MAX_COFFEE_TYPES 10
#define MAX_BARISTAS 10

// Define the coffee types and their preparation times
struct CoffeeType
{
    char name[20];
    int preparation_time;
};

struct CoffeeType coffee_types[MAX_COFFEE_TYPES];

// Define the customers
struct Customer
{
    int id;
    char coffee_name[20];
    int arrival_time;
    int patience_time;
    int waiting_time;
};

struct Customer customers[MAX_CUSTOMERS];

// Define global variables
int B, K, N;
int served_customers = 0;
int coffee_preparation_time = 1;
int wasted_coffees = 0;
int total_waiting_time = 0;
int start_time, end_time;
int curr_time = 0;

// Mutex locks and semaphores
pthread_mutex_t mutex = PTHREAD_MUTEX_INITIALIZER;
pthread_cond_t cond;
sem_t barista_available[MAX_BARISTAS];
int finish_times[MAX_BARISTAS];
int left_flags[MAX_CUSTOMERS];
int cust_done[MAX_CUSTOMERS];
time_t startTime, currentTime;
int elapsedSeconds;
// Function to serve a customer
void *serve_customer(void *c_id)
{
    while (served_customers < N)
    {
        int cust_id = *(int *)c_id;
        // printf("%d ", cust_id);
        //  return 0;
        // pthread_mutex_lock(&mutex);
        // while (cust_id != served_customers)
        //     pthread_cond_wait(&cond, &mutex);
        // pthread_mutex_unlock(&mutex);

        pthread_mutex_lock(&mutex);
        int customer_id = served_customers;
        served_customers++;
        // pthread_cond_signal(&cond);
        pthread_mutex_unlock(&mutex);

        if (customer_id >= N)
        {
            break;
        }

        int arrival_time = customers[customer_id].arrival_time;
        int patience_time = customers[customer_id].patience_time;
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
            sleep(0.01);
        }
        // printf("*%d %d %d*\n",customer_id,curr_time,arrival_time);
        //  while (curr_time < arrival_time)
        //     sleep(0.01);
        curr_time = arrival_time;
        pthread_mutex_lock(&mutex);
        printf("\x1B[37mCustomer %d arrives at %d second(s)\x1B[0m\n", customer_id + 1, arrival_time);
        printf("\x1B[33mCustomer %d orders a %s\x1B[0m\n", customer_id + 1, customers[customer_id].coffee_name);
        pthread_mutex_unlock(&mutex);

        // pthread_mutex_lock(&mutex);
        // sleep(1);

        // pthread_mutex_unlock(&mutex);

        // Find the preparation time using coffee name
        int preparation_time = -1;
        for (int i = 0; i < K; i++)
        {
            if (strcmp(coffee_types[i].name, customers[customer_id].coffee_name) == 0)
            {
                preparation_time = coffee_types[i].preparation_time;
                break;
            }
        }

        if (preparation_time == -1)
        {
            printf("INVALID ORDER");
            return 0;
        }
        // sleep(arrival_time - coffee_preparation_time);
        // sleep(0.01);
        // int barista_id = *(int *)barista_id1;
        // printf("*%d %d*\n", customer_id, cust_done[customer_id - 1]);

        int selected = -1;
        while (selected == -1)
        {
            for (int i = 0; i < B; i++)
            {
                pthread_mutex_lock(&mutex);
                time(&currentTime);
                elapsedSeconds = difftime(currentTime, startTime);
                int curr = elapsedSeconds;
                pthread_mutex_unlock(&mutex);
                // printf("%d %d\n",cust_id,curr);
                if (curr > arrival_time + patience_time && left_flags[customer_id] == 0)
                {
                    pthread_mutex_lock(&mutex);
                    printf("\x1B[31mCustomer %d leaves without their order at %d second(s)\x1B[0m\n", customer_id + 1, arrival_time + patience_time + 1);
                    customers[customer_id].waiting_time = patience_time; // Left without coffee beginning to be prepared
                    left_flags[customer_id] = 1;
                    cust_done[customer_id] = 1;
                    wasted_coffees++;
                    // int customer_id=*(int *)barista_id1;
                    pthread_mutex_unlock(&mutex);

                    total_waiting_time += customers[customer_id].waiting_time;
                    return 0;
                    // arrival_time=1000;
                    // patience_time=1000;
                }
                // sleep(0.01);
                if (sem_trywait(&barista_available[i]) != 0)
                    continue;
                else
                {
                    if (customer_id != 0 && cust_done[customer_id - 1] == 0)
                    {
                        sem_post(&barista_available[i]);
                        continue;
                    }
                    selected = i;
                    break;
                }

                
            }
        }
        // sem_wait(&barista_available[selected]);
        int curr = 0;
        pthread_mutex_lock(&mutex);
        time(&currentTime);
        elapsedSeconds = difftime(currentTime, startTime);
        curr = elapsedSeconds;
        pthread_mutex_unlock(&mutex);
        // printf("%d %d\n",cust_id,curr);
        if (curr > arrival_time + patience_time && left_flags[customer_id] == 0)
        {
            pthread_mutex_lock(&mutex);
            printf("\x1B[31mCustomer %d leaves without their order at %d second(s)\x1B[0m\n", customer_id + 1, arrival_time + patience_time + 1);
            customers[customer_id].waiting_time = patience_time; // Left without coffee beginning to be prepared
            left_flags[customer_id] = 1;
            cust_done[customer_id] = 1;
            wasted_coffees++;
            // int customer_id=*(int *)barista_id1;
            pthread_mutex_unlock(&mutex);
            sem_post(&barista_available[selected]);

            total_waiting_time += customers[customer_id].waiting_time;
            return 0;
            // arrival_time=1000;
            // patience_time=1000;
        }
        if (customer_id != 0)
        {
            while (cust_done[customer_id - 1] == 0)
                sleep(0.01);
        }
        int b_start=0;
        pthread_mutex_lock(&mutex);
        time(&currentTime);
        elapsedSeconds = difftime(currentTime, startTime);
        curr = elapsedSeconds;
        if (curr < arrival_time +1 || curr<1+finish_times[selected])
        sleep(1);
        time(&currentTime);
        elapsedSeconds = difftime(currentTime, startTime);
        curr = elapsedSeconds;
        printf("\x1B[36mBarista %d begins preparing the order of customer %d at %d second(s)\x1B[0m\n", selected + 1, customer_id + 1, curr);
        b_start=curr;
        cust_done[customer_id] = 1;
        customers[customer_id].waiting_time = curr - arrival_time;
        pthread_mutex_unlock(&mutex);
        for (int i = 0; i < preparation_time; i++)
        {
            sleep(1);
            finish_times[selected]++;
            curr_time = finish_times[selected];
            pthread_mutex_lock(&mutex);
            time(&currentTime);
            elapsedSeconds = difftime(currentTime, startTime);
            finish_times[selected] = elapsedSeconds;
            curr_time = elapsedSeconds;
            pthread_mutex_unlock(&mutex);
            // printf("*%d %d*\n",customer_id,finish_times[selected]);
            if (finish_times[selected] > arrival_time + patience_time && left_flags[customer_id] == 0)
            {
                pthread_mutex_lock(&mutex);
                printf("\x1B[31mCustomer %d leaves without their order at %d second(s)\x1B[0m\n", customer_id + 1, arrival_time + patience_time + 1);
                wasted_coffees++;
                left_flags[customer_id] = 1; // so the message won't print again
                cust_done[customer_id] = 1;
                // int customer_id=*(int *)barista_id1;
                pthread_mutex_unlock(&mutex);
                // arrival_time=1000;
                // patience_time=1000;
            }
            // sleep(0.01); // so another thread can come
            //  else if(curr_time)
        }

        // finish_times[selected]+=preparation_time;
        // sleep(preparation_time);
        //  int preparation_finish_time = curr_time + preparation_time;
        int preparation_finish_time = finish_times[selected] + 1;
        finish_times[selected]++;

        curr_time = preparation_finish_time;
        pthread_mutex_lock(&mutex);
        time(&currentTime);
        elapsedSeconds = difftime(currentTime, startTime);
        preparation_finish_time = elapsedSeconds;
        finish_times[selected] = elapsedSeconds;
        curr_time = elapsedSeconds;
        // printf("*%d\n",elapsedSeconds);
        // finish_times[selected] = preparation_finish_time;
        printf("\x1B[34mBarista %d completes the order of customer %d at %d seconds\x1B[0m\n", selected + 1, customer_id + 1, b_start+preparation_time);
        pthread_mutex_unlock(&mutex);
        if (preparation_finish_time <= arrival_time + patience_time)
        {

            pthread_mutex_lock(&mutex);
            printf("\x1B[32mCustomer %d leaves with their order at %d second(s)\x1B[0m\n", customer_id + 1, b_start+preparation_time);
            customers[customer_id].waiting_time = b_start - arrival_time; // Assuming coffee prep time is not included in waiting time
            cust_done[customer_id] = 1;
            // printf("#%d %d\n",curr,arrival_time);
            //  int customer_id=*(int *)barista_id1;
            pthread_mutex_unlock(&mutex);
            // finish_times[selected]=preparation_finish_time+1;
        }
        else
        {
            // printf("\x1B[31mCustomer %d leaves without their order at %d second(s)\x1B[0m\n", customer_id + 1, arrival_time + patience_time + 1);
            // customers[customer_id].waiting_time = patience_time;
            // wasted_coffees++;
            // cust_done[customer_id]=1;
            // printf("\x1B[34mBarista %d completes the order of customer %d at %d seconds\x1B[0m\n", selected + 1, customer_id + 1, preparation_finish_time);
        }
        sem_post(&barista_available[selected]);

        total_waiting_time += customers[customer_id].waiting_time;
        coffee_preparation_time += curr_time;
    }

    return NULL;
}

int main()
{
    scanf("%d %d %d", &B, &K, &N);
    pthread_mutex_init(&mutex, NULL);
    pthread_cond_init(&cond, NULL);
    // Initialize coffee types
    for (int i = 0; i < K; i++)
    {
        scanf("%s %d", coffee_types[i].name, &coffee_types[i].preparation_time);
    }

    // Initialize customers and reassign customer IDs starting from 0
    for (int i = 0; i < N; i++)
    {
        int arrival_time, patience_time, id;
        char coffee_name[20];
        scanf("%d %s %d %d", &id, coffee_name, &arrival_time, &patience_time);
        customers[i].id = id - 1;
        strcpy(customers[i].coffee_name, coffee_name);
        customers[i].arrival_time = arrival_time;
        customers[i].patience_time = patience_time;
        left_flags[i] = 0;
        cust_done[i] = 0;
    }

    pthread_t customer_threads[N];
    int barista_ids[B];

    // Initialize semaphores
    for (int i = 0; i < B; i++)
    {
        sem_init(&barista_available[i], 0, 1);
        barista_ids[i] = i;
        finish_times[i] = customers[i].arrival_time;
    }
    time(&startTime);
    for (int i = 0; i < N; i++)
    {
        int *c_id = malloc(sizeof(int)); // Allocate memory for c_id
        if (c_id == NULL)
        {
            exit(1);
        }
        *c_id = i;
        // while(customers[i].arrival_time>curr_time)
        // {
        //     // end_time=clock();
        //     // double elapsed_time=(end_time-start_time)/CLOCKS_PER_SEC;
        //     // printf("*%f ",elapsed_time);
        //     // curr_time=(int)elapsed_time;
        // }
        pthread_create(&customer_threads[i], NULL, serve_customer, c_id);
    }
    for (int i = 0; i < N; i++)
    {
        pthread_join(customer_threads[i], NULL);
    }

    for (int i = 0; i < B; i++)
    {
        sem_destroy(&barista_available[i]);
    }
    pthread_mutex_destroy(&mutex);
    pthread_cond_destroy(&cond);
    // Calculate average waiting time
    float average_waiting_time = (float)total_waiting_time / N;
    printf("Average Waiting Time (not including coffee preparation time): %.2f seconds\n", average_waiting_time);

    // Print the number of wasted coffees
    printf("%d coffee(s) wasted\n", wasted_coffees);

    return 0;
}
