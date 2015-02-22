#ifndef QUEUE_H_INCLUDED
#define QUEUE_H_INCLUDED

#define isempty(queue) (queue->front == NULL && queue->rear == NULL && queue->size == 0)

typedef struct Node {
    Token data;
    struct Node *next;
} Node;

typedef struct {
    Node *front;
    Node *rear;
    int size;
} Queue;

Queue *init();
void destroy(Queue *queue);
Node *enqueue(Queue *queue, Token token);
Node *dequeue(Queue *queue, Token *token);

#endif /* TOKEN_H_INCLUDED */
