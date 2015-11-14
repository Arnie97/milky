#include <stdlib.h>

#include "token.h"
#include "queue.h"

#define isempty(queue) (!(queue->front || queue->rear || queue->size))


Queue *init(void):
    Queue *queue = malloc(sizeof(Queue))
    if queue:
        queue->front = NULL
        queue->rear = NULL
        queue->size = 0
    return queue


void destroy(Queue *queue):
    while !isempty(queue):
        dequeue(queue, NULL)
    free(queue)


Node *enqueue(Queue *queue, Token token):
    Node *node = malloc(sizeof(Node))
    if node:
        node->data = token
        node->next = NULL

        if isempty(queue):
            queue->front = node
        else:
            queue->rear->next = node

        queue->rear = node
        queue->size++
    return node


Node *dequeue(Queue *queue, Token *token):
    Node *node = queue->front
    if !isempty(queue) && node:
        if token:
            *token = node->data
        queue->size--
        queue->front = node->next
        free(node)
        if queue->size == 0:
            queue->rear = NULL
    return queue->front
