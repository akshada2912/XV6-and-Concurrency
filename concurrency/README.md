REPORT:



CONCURRENCY:
1. Cafe:
    If there were infinite baristas, a customer could get a barista as soon as they entered the cafe - hence wait time would reduce to only 1s per customer. Thus avg. wait time would be 1s. In contrast, if there are less baristas than customers, a customer would have
    to wait for a barista to finish their current order before getting the barista - which would increase avg. wait time

2. Ice Cream Parlor:
    1: Minimize incomplete orders: To minimize incomplete orders, we can implement a prioroty-based mechanism. Customers with
                                    shorter preparation times could be given a higher priority, which would minimize the wait 
                                    times for other customers, hence maximizing the number of customers who get complete orders

    2: Ingredient Replenishment: If ingredients can be replenished, then once an ingredient reaches some low threshold quantity, we
                                 contact the nearest supplier to get that ingredient. In the mean time, if a customer wanting that
                                 ingredient arrives, we ask them whether they are willing to wait for the remaining time till that 
                                 ingredient arrives. But if the remaining time is greater than that customer's tolerance time, we
                                 must reject them. If the customer waits, we can put there order on hold until that ingredient arrives.

    3: Unserviced Orders: To reduce number of unserviced orders, we can implement the ideas mentioned above (prioritization and
                          ingredient tracking). In addition, we can keep customers in a queue and reject a customer c immedieately if
                          sum of preparation times of all customers before c, excluding customers waiting for ingredient replenishment is greater than tolerance time of c. Then c's order would not be unserviced, and the people after c still have a chance to get their orders. If we remove such customers from the queue, it would reduce number of unserviced orders.