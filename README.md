# wechat-group-stat


## usage

- download the wechat db from the phone(has to enable the sshd in your phone)

 `rsync  -aP root@192.168.178.20:/data/data/com.tencent.mm/MicroMsg/96daf633e8fe3b4ae711c91836eeac97/EnMicroMsg.db .`

- decrypted database and generate the statistics file

```
sqlcipher EnMicroMsg.db 'PRAGMA key = "******"; PRAGMA cipher_use_hmac = off; PRAGMA kdf_iter = 4000; ATTACH DATABASE "decrypted_database.db" AS decrypted_database KEY "";SELECT sqlcipher_export("decrypted_database");DETACH DATABASE decrypted_database;' && ruby group-stat.rb  
```



- Upload the statistics file to a webserver

`scp stat.html xxxx@xxxx.xxx.com:/to/path/xxx/`


## Reference of how to decryte the wechat db.

https://www.zhihu.com/collection/20574867  
https://maskray.me/blog/2014-10-14-wechat-export  
mucha gracias to Mingo
