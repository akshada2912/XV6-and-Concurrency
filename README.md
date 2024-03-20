# 1. Modified Priority Based Scheduler in xv-6.
Implement a preemptive priority-based scheduler that selects the process with the highest priority for execution. In case two or more processes have the same priority, we use the number of times the process has been scheduled to break the tie. If the tie remains, use the start-time of the process to break the tie(processes with lower start times should be scheduled further).

There are two types of priorities:
The Static Priority of a process (SP) can be in the range 0-100. A smaller value will represent higher priority. Set the default priority of a process as 50.
The Dynamic Priority (DP) of a process depends on its Static Priority and RBI (recent behaviour index).
The RBI (Recent Behaviour Index) of a process measures its recent behavior and is used to adjust its dynamic priority. It is a weighted sum of three factors: Running Time (RTime), Sleeping Time (STime), and Waiting Time (WTime). The default value of RBI is 25.

Definition of the variables:

Rtime: The total time the process has been running since it was last scheduled.

Stime: The total time the process has spent sleeping (i.e., blocked and not using CPU time) since it was last scheduled.

Wtime: The total time the process has spent in the ready queue waiting to be scheduled.

RBI=max(Int((3∗RTime−STime−WTime*50)/(Rtime+Wtime+Stime +1)),0)
DP=min(SP+RBI,100)
Used Dynamic Priority (DP) to schedule processes.

To change the Static Priority ,added a new system call set_priority():
int set_priority(int pid, int new_priority)
The system call returns the old Static Priority of the process. In case the priority of the process increases(the value is lower than before), then rescheduling should be done. Note that calling this system call will also reset the Recent Behaviour Index (RBI) of the process to 25 as well.

Also implemented a user program setpriority, which uses the above system call to change the priority. And takes the syscall arguments as command-line arguments:
setpriority pid priority

# 2. Copy on Write Fork in xv-6
In xv6 the fork system call creates a duplicate process of the parent process and also copies the memory content of the parent process into the child process. This results in inefficient usage of memory since the child may only read from memory.

The idea behind a copy-on-write is that when a parent process creates a child process then both of these processes initially will share the same pages in memory and these shared pages will be marked as copy-on-write which means that if any of these processes will try to modify the shared pages then only a copy of these pages will be created and the modifications will be done on the copy of pages by that process and thus not affecting the other process.

The basic plan in COW fork is for the parent and child to initially share all physical pages, but to map them read-only. Thus, when the child or parent executes a store instruction, the RISC-V CPU raises a page-fault exception. In response to this exception, the kernel makes a copy of the page that contains the faulted address. It maps one copy read/write in the child’s address space and the other copy read/write in the parent’s address space. After updating the page tables, the kernel resumes the faulting process at the instruction that caused the fault. Because the kernel has updated the relevant PTE to allow writes, the faulting instruction will now execute without a fault.


# Concurrency
1. Cafe Sim
Simulated the operation of a small cafe. The cafe owner wants to ensure that customers can get their coffee efficiently.

DURING THE SIMULATION:
There are K coffee types.
Each coffee type c takes some time t_c to prepare.
The cafe has B baristas.

There are N customers waiting to get their coffee.
Each customer i arrives at some time t_arr_i, and orders only one coffee x.
Each customer i arrives at some tolerance time tol_i, after which their patience runs out and they will instantly leave the cafe (bad).
ASSUMPTIONS:
Simulation begins from 0 seconds.
The cafe has unlimited ingredients.
If a customer arrives at time t, they place the order at time t, and the coffee starts getting prepared at time t+1.
If a customer arrives at time t, and they have tolerance time tol => they collect their order only if it gets done on or before t + tol.
Once an order is completed, the customer picks it up and leaves instantaneously.
If a customer was already waiting, once a barista finishes their previous order, say at time t, they can start making the order of the waiting customer at time t+1.
The cafe has infinite seating capacity.

Utilized multi-threading concepts and avoid potential issues like deadlocks and busy waiting. Implemented the problem using semaphores and mutex locks to ensure thread safety.

INPUT FORMAT (ALL SPACE SEPARATED):
The first line contains B K N The next K lines contain c t_c The next N lines contain i x t_arr_i tol_i

OUTPUT FORMAT:
When a customer c arrives, print [white colour] Customer c arrives at t second(s)
When a customer c places their order, print [yellow colour] Customer c orders an espresso

When a barista b begins preparing the order of customer c, print [cyan colour] Barista b begins preparing the order of customer c at t second(s)
When a barista b successfully complete the order of customer c, print [blue colour] Barista b successfully completes the order of customer c

If a customer successfully gets their order, print [green colour] Customer c leaves with their order at t second(s)
If a customer’s patience runs out, print [red colour] Customer c leaves without their order at t second(s)

2. Ice Cream Parlor Sim 
Sunny’s Ice Cream Parlor is renowned for its delectable ice cream creations and has garnered fame through media coverage. To meet the growing demand, Sunny has expanded the offerings, employing skilled ice cream machines. Simulated the operation of Sunny’s Ice Cream Parlor.

DURING THE SIMULATION:
There are N ice cream machines.
Every ice cream machine m works from time tm_start to time tm_stop.

There are F ice cream flavours
Every ice cream flavour f takes unique time t_f to prepare.

There are T toppings.
Every topping t takes constant time t_t to put.
A topping t is present in limited quantity, q_t

There is a capacity of K customers in the parlour.
A customer c arrives at time t_arr
ASSUMPTIONS:
Simulation begins from 0 seconds.
If a customer arrives at time t, they place the order at time t, and the order starts getting prepared at time t+1.
If a customer’s order can only be partially completed, they must be rejected completely, no part of their order should waste ingredients.
If a customer leaves due to ingredient shortages, they leave the second they’re informed (at t), and their spot becomes free from the next second i.e. t+1.
Once an entire order is completed, the customer picks it up and leaves instantaneously.
A machine cannot start preparing an order if it will have to stop working in the middle of that order.
If a machine starts working at time t, and a customer was already waiting since some time t, the machine can instantly start preparing their order.
Here’s a structured breakdown of the scenario:

Ice Cream Machines:
Sunny’s parlor has N ice cream machines, and they have individual work shifts.
Ice machines unfortunately work at different times during the day.
Ice Cream Varieties:
Sunny offers an assortment of ice cream flavors, each with its own preparation time and ingredient requirements.
Some ingredients, like vanilla and chocolate syrup, are available in abundance, while others, such as fresh fruits and whipped cream, are limited for the day.
If all limited ingredients are depleted, the parlor closes for the day.
Customers:
The parlour can accommodate a maximum of K customers at a time. Customers can place orders for multiple ice creams with diverse flavors and toppings.
Customers submit their orders immediately upon entering. If ingredient shortages prevent fulfillment, they receive immediate notification (after order is taken) and can choose to exit the parlour.
If an order can be fulfilled, customers must wait for their ice creams to be prepared and brought to the pickup spot.
Your simulation should utilize multi-threading concepts and avoid potential issues like deadlocks and busy waiting. In your report, provide implementation details and address the given follow-up questions. Make sure to colour code your output using the specified colours.

INPUT FORMAT (EVERYTHING IS SPACE SEPARATED):
The first line contains N K F T The next N lines contain machine timings tm_start tm_stop The next F lines contain f t_f The next T lines contain t q_t [Note: q_t will be given -1 for unlimited quantity]

The rest of the lines will have the structure c t_arr number of ice creams they want to order flavour of ice cream 1 topping 1 topping 2 … topping n … flavour of ice cream n topping 1 topping 2 … topping n

OUTPUT FORMAT:
When a customerc enters at time t, print [white colour] Customer c enters at t second(s)
Print their order [yellow colour]:
Customer c orders 2 ice creams
Ice cream 1: vanilla caramel
Ice cream 2: chocolate candy
When a machine m is starts preparing the order of customer c, print [cyan colour] Machine m starts preparing ice cream 1 of customer c at t seconds(s)
When a machine m is completes preparing the order of customer c, print [blue colour] Machine m completes preparing ice cream 1 of customer c at t seconds(s)

When a customer’s order is complete, as they will pick it up immidiately, print [green colour] Customer c has collected their order(s) and left at t second(s)
If a customer was rejected due to ingredient shortage, print [red colour] Customer c left at t second(s) with an unfulfilled order
If a customer c was not serviced even when the parlour is closing (last machine has stopped working), print [red colour] Customer c was not serviced due to unavailability of machines

When a machine m starts working, print [orange colour] Machine m has started working at t second(s)
When a machine m stops working, print [orange colour] Machine m has stopped working at t second(s)