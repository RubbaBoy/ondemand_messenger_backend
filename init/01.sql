
CREATE DATABASE IF NOT EXISTS ondemand;
GRANT ALL ON `ondemand`.* TO 'user'@'%';

USE ondemand;

# The book
CREATE TABLE IF NOT EXISTS books (
    book_id  int auto_increment,
    name     varchar(128),
    password varchar(128),
    PRIMARY KEY (book_id)
);

# The numbers stored in a book
CREATE TABLE IF NOT EXISTS numbers (
    number_id int auto_increment,
    name      varchar(128),
    number    varchar(13),
    book_id   int,
    PRIMARY KEY (number_id),
    FOREIGN KEY (book_id) REFERENCES books (book_id)
);
