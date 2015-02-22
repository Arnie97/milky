#include "queue.h"

Queue *
init()
{
    Queue *queue = malloc(sizeof(Queue));
    if (queue != NULL) {
        queue->front = NULL;
        queue->rear = NULL;
        queue->size = 0;
    }
    return queue;
}

void
destroy(Queue *queue)
{
    while(!isempty(queue)) {
        dequeue(queue, NULL);
    }
    free(queue);
}

Node *
enqueue(Queue *queue, Token token)
{
    Node *node = malloc(sizeof(Node));
    if (node != NULL) {
        node->data = token;
        node->next = NULL;

        if (isempty(queue)) {
            queue->front = node;
        } else {
            queue->rear->next = node;
        }
        queue->rear = node;
        queue->size++;
    }
    return node;
}

Node *
dequeue(Queue *queue, Token *token)
{
    Node *node = queue->front;
    if (!isempty(queue) && node != NULL) {
        if (token != NULL) {
            *token = node->data;
        }
        queue->size--;
        queue->front = node->next;
        free(node);
        if (queue->size == 0)
            queue->rear = NULL;
    }
    return queue->front;
}
