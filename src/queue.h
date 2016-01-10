#ifndef QUEUE_H_INCLUDED
#define QUEUE_H_INCLUDED

typedef struct Node {
    Token data;
    struct Node *next;
} Node;

typedef struct Queue {
    Node *front;
    Node *rear;
    int size;
} Queue;

Queue *init();
void destroy(Queue *queue);
Node *enqueue(Queue *queue, Token token);
Node *dequeue(Queue *queue, Token *token);

#endif /* TOKEN_H_INCLUDED */
