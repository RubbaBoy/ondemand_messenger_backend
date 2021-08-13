# The database init script

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

# The access token API keys
CREATE TABLE IF NOT EXISTS overrideTokens (
    id    int auto_increment,
    label varchar(128),
    token varchar(64),
    PRIMARY KEY (id)
);

# A log to track the amount of sent messages
CREATE TABLE IF NOT EXISTS sentMessages (
    count int
);

# UPDATE sentMessages SET count = count + 1