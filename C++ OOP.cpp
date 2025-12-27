#include<iostream>
using namespace std;

template<typename T>
class Hash {//creating the hash table
   
public:
    Hash(T data);//Constructor 

    T data; //data
};

template<typename T>
class HashMap {

public:
    HashMap();//constructor
    void setInfo(int D, int i);
    void insertHashCell(T data);//insert (T) object into the HashMap
    int getMapSize();
    int getGapValue();
    int findKey(T data);//i%D
    void displayTable() {
        int i = 0;
        while ( i < getMapSize()) {
            if (arr[i] != NULL ) {
                cout << arr[i]->data << endl;
            }
            else {
                cout << "-1" << endl;
            }
            i++;
        }
    }

    
private:
    Hash<T> **arr;// all (T) objects
    int hashSize;
    int gap; //LinearProbing parameter
};


template<typename T>
Hash<T>::Hash(T data) { // Storing the data at the key location of the hash 
   
    this->data = data;
}

template<typename T>
HashMap<T>::HashMap() {
    int capacity = 100;
    arr = new Hash<T>*[capacity];
    for (int k = 0; k < capacity; k++) {
        arr[k] = NULL;
    }
    
}

template<typename T>
void HashMap<T>::setInfo(int D, int i) {
    hashSize = D;
    gap = i;
}

template<typename T>
void HashMap<T>::insertHashCell(T data) {
    
    Hash<T> *temp = new Hash<T>(data);
    int index = findKey(data);

    
    while (arr[index] != NULL ) {
      
        index = (index + getGapValue()) % getMapSize(); //Linear Probing
        
    }

    arr[index] = temp;
}


template<typename T>
int HashMap<T>::findKey(T data) {
    return data % hashSize;
}

template<typename T>
int HashMap<T>::getMapSize() { return hashSize; }

template<typename T>
int HashMap<T>::getGapValue() { return gap; }

/*template<typename T>
void HashMap<T>::displayTable() {

    for (int i = 0; i < getMapSize(); i++) {
        if (arr[i] != NULL ) {
            cout << arr[i]->data<<endl;
        }
        else { 
            cout << "-1"<<endl; }
    }
}*/

/*void printHashTable(vector<int> arr, int size)
{
    int i;
    for (i = 0; i < size; i++)
        cout << "arr[" << i << "] = " << arr[i];
}*/

int main()
{
    
    int D, i, x;
    cin >> D;
    cin >> i;
    HashMap<int>* m = new HashMap<int>;
    m->setInfo(D, i);
    while (cin >> x) {
    m->insertHashCell(x);}
    m->displayTable();




    return 0;
}