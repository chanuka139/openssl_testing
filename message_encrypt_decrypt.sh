#!/bin/bash

BASE_DIR=/tmp
INPUT_FILE=test.txt

rm -rf $BASE_DIR/sender $BASE_DIR/receiver
echo "Creating the message file at "$BASE_DIR/$INPUT_FILE
echo "This is a very secret message" >> $BASE_DIR/$INPUT_FILE

echo "Creating the directories"
mkdir -p $BASE_DIR/sender $BASE_DIR/receiver

mv $BASE_DIR/$INPUT_FILE $BASE_DIR/sender/

echo "Encrypting the file"
openssl   enc   -aes-256-cbc   -in $BASE_DIR/sender/$INPUT_FILE   -out  $BASE_DIR/sender/encrypted.bin

echo "Sending encrypted message to receiver"
cp $BASE_DIR/sender/encrypted.bin $BASE_DIR/receiver/

echo "Decrypting the message"
openssl   enc   -aes-256-cbc   -d   -in  $BASE_DIR/receiver/encrypted.bin   -out   $BASE_DIR/receiver/msgdecrypted.txt

echo "Following is the decrypted message content"
cat $BASE_DIR/receiver/msgdecrypted.txt

echo "Generating RSA key pairs for sender"
openssl   genrsa   -out  $BASE_DIR/sender/sender-private-key.pem   1024
openssl   rsa   -in  $BASE_DIR/sender/sender-private-key.pem   -pubout   -out  $BASE_DIR/sender/sender-public-key.pem

echo "Generating RSA key pairs for receiver"
openssl   genrsa   -out  $BASE_DIR/receiver/receiver-private-key.pem   1024
openssl   rsa   -in  $BASE_DIR/receiver/receiver-private-key.pem   -pubout   -out  $BASE_DIR/receiver/receiver-public-key.pem


echo "Exchanging the public keys"
cp $BASE_DIR/sender/sender-public-key.pem $BASE_DIR/receiver/
cp $BASE_DIR/receiver/receiver-public-key.pem $BASE_DIR/sender/

echo "Encrypt the text file at sender with Receiver public key"
openssl  rsautl  -encrypt  -inkey  $BASE_DIR/sender/receiver-public-key.pem   -pubin  -in  $BASE_DIR/sender/$INPUT_FILE  -out  $BASE_DIR/sender/encrypted_pub_key.bin
echo "Sending the encrypted file to receiver"
cp $BASE_DIR/sender/encrypted_pub_key.bin $BASE_DIR/receiver/
echo "Decrypting the encrypted file at receiver"
openssl   rsautl   -decrypt   -inkey  $BASE_DIR/receiver/receiver-private-key.pem     -in  $BASE_DIR/receiver/encrypted_pub_key.bin   -out  $BASE_DIR/receiver/msgdecrypted_keypair.txt
echo "Content of the decrypted file with private key of the receiver"
cat $BASE_DIR/receiver/msgdecrypted_keypair.txt

echo "Creating a digest of the source test file"
openssl dgst -sha1 -out $BASE_DIR/sender/msg.dgst $BASE_DIR/sender/$INPUT_FILE

echo "Create a signature file using the digest file of the original message"
#openssl   rsautl   -sign   -inkey  $BASE_DIR/sender/sender-private-key.pem   -in  $BASE_DIR/sender/msg.dgst   -out  $BASE_DIR/sender/signature.bin
openssl   dgst   -sha1   -sign  $BASE_DIR/sender/sender-private-key.pem  -out  $BASE_DIR/sender/signature.bin    $BASE_DIR/sender/$INPUT_FILE
echo "Sending the signature to the receiver"
cp $BASE_DIR/sender/signature.bin $BASE_DIR/receiver/


echo "Verifying the digest at the receiver end"
openssl   dgst   -sha1   -verify  $BASE_DIR/receiver/sender-public-key.pem    -signature  $BASE_DIR/receiver/signature.bin  $BASE_DIR/receiver/msgdecrypted.txt



