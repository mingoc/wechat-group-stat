#!/usr/bin/ruby
# coding: utf-8


require 'sqlite3'
require 'kramdown'

begin
  talker2name = {}
  username2name = {}
  activity_stat={}

  db = SQLite3::Database.open 'decrypted_database.db'
  db.results_as_hash = true
  db.execute('SELECT talker,displayName FROM fmessage_conversation').each {|row|
    talker2name[row['talker']] = row['displayName']
  }
  db.execute('SELECT username,nickname FROM rcontact').each {|row|
    username = row['username']
    nickname = row['nickname']
    if nickname != ''
      if username =~ /@chatroom$/
        talker2name[username] = nickname == '' ? username : nickname
      else
        username2name[username] = nickname == '' ? username : nickname
      end
    end
  }


  db.execute("select memberlist from chatroom where chatroomname='3783139122@chatroom'").each do |row|
    memberlist = row['memberlist']
    activity_stat = memberlist.split(/;/).inject({}) do |stat, id|
      stat[id]=0
      stat
    end   
  end



  activity_detail=[]
  db.execute("SELECT createTime,talker,content FROM message where talker='3783139122@chatroom'").each {|row|
    time,talker,content = row.values_at 'createTime','talker','content'
    next unless content
    next if(Time.now - Time.at(time/1000) > 60*60*24*14 )   
    next if content =~ /关键字/       #skip. 这个消息是群主发通告。打卡不应该包含“关键字”。
    next if content =~ /微信红包/       #skip.     
    next if content =~ /^~SEMI_XML~/


  
    if content.match('#打卡')
      puts "========"
           
      id=content.scan(/^(.+?):\n/)[0]? content.scan(/^(.+?):\n/)[0][0]:"chenxing_2489"         # if the id is empty then it is me
      puts id
      #name = talker2name.fetch talker, talker
      name=username2name.fetch(id, 'xxxx')    
      activity_stat[id]+=1
      content.sub!(/^#{id}:\n/) {|x| "" }      
      activity_detail.push "#{Time.at(time/1000).strftime('%F %R')}\t#{name}\t#{content}"
    end    
  }

  output =  "# Notice \n\n"
  output <<  "* 打卡请包含关键字 *#打卡*. 在群里面打卡的例子: *#打卡 跑步10公里*  \n"
  output <<  "* 统计周期为14天 \n"
  output <<  "\n"
  
  output <<  "# Activities statistics of Last 2 weeks - Updated on #{Time.now}  \n\n"
  output <<  "| Name |Times| \n"

  activity_stat.sort_by{|k,v| v}.reverse.each do |record|    
    name=username2name.fetch(record[0], 'xxxx')
    next if name=='Robot'
    output<< "|#{name} |#{record[1]} | \n "
  end

 output <<  "\n# Activities detail \n"
  activity_detail.each do |record|
     output <<  "* #{record} \n\n"
    puts record
  end

  output <<  "# Source code \n\n"
  output <<  " [https://github.com/mingoc/wechat-group-stat](https://github.com/mingoc/wechat-group-stat)"

  
  File.open('stat.html', 'w') { |file|  file.write( '<meta charset="utf-8"> <meta http-equiv="Cache-Control" content="no-cache, no-store, must-revalidate" /> <meta http-equiv="Pragma" content="no-cache" /> <meta http-equiv="Expires" content="0" />' +  Kramdown::Document.new(output).to_html) }



  
rescue SQLite3::Exception => e
  puts e
ensure
  db.close if db
end
