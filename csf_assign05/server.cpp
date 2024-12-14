// #include <iostream>
// #include <cassert>
// #include <memory>
// #include "csapp.h"
// #include "exceptions.h"
// #include "guard.h"
// #include "server.h"

// Server::Server()
//   // TODO: initialize member variables
// {
//   // TODO: implement
// }

// Server::&operator=( const Server & server) {

// }
// Server::~Server()
// {
//   // TODO: implement
// }

// void Server::listen( const std::string &port )
// {
//   // TODO: implement
// }

// void Server::server_loop()
// {
//   // TODO: implement

//   // Note that your code to start a worker thread for a newly-connected
//   // client might look something like this:
// /*
//   ClientConnection *client = new ClientConnection( this, client_fd );
//   pthread_t thr_id;
//   if ( pthread_create( &thr_id, nullptr, client_worker, client ) != 0 )
//     log_error( "Could not create client thread" );
// */
// }


// void *Server::client_worker( void *arg )
// {
//   // TODO: implement

//   // Assuming that your ClientConnection class has a member function
//   // called chat_with_client(), your implementation might look something
//   // like this:
// /*
//   std::unique_ptr<ClientConnection> client( static_cast<ClientConnection *>( arg ) );
//   client->chat_with_client();
//   return nullptr;
// */
// }


// void Server::log_error( const std::string &what ) {
//   std::cerr << "Error: " << what << "\n";
// }

// // TODO: implement member functions


#include <pthread.h>
#include <iostream>
#include <string>
#include "csapp.h"


class ConnInfo {
    private:
        rio_t client;
    
    public:
        ConnInfo(int client_sock) {
            rio_readinitb(&client, client_sock);
        }

        bool chat() {
            char buf[MAXLINE];
            ssize_t n = rio_readlineb(&client, buf, MAXLINE);

            std::string message(buf, n);

            std::string pre = "this is your message: ";

            if(rio_writen(client.rio_fd, pre.c_str(), pre.length())
                != pre.length()
            ) {
                return false;
            }

            if(rio_writen(client.rio_fd, message.c_str(), n) != n) {
                return false;
            }

            return true;
        }

        void close_client() {
            close(client.rio_fd);
        }
};

void *worker(void *arg) {
    ConnInfo *client_info = (ConnInfo*) arg;

    if (client_info->chat()) {
        std::cout << "chat completed successfully" << std::endl;
    } else {
        std::cout << "chat failed" << std::endl;
    }

    free(client_info);

    return nullptr;
}

int main() {
    std::string port = "5010";

    int ssocket = Open_listenfd(port.data());

    int client = Accept(ssocket, NULL, NULL);
    if (client < 0) {
        close(ssocket);
        return 1;
    }
    
    struct ConnInfo *conn_info = new ConnInfo(client);

    pthread_t thr_id;
    pthread_create(&thr_id, NULL, worker, conn_info);
    pthread_join(thr_id, nullptr);
    close(ssocket);

    return 0;
}