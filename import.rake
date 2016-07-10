# coding: utf-8

require 'sqlite3'
desc "Imports a CSV file into an ActiveRecord table"



task :import, [:filename] => :environment do    
  begin
  talker2name = {}
  username2name = {}
  activity_stat={}

  db = SQLite3::Database.open 'decrypted_database.db'
  db.results_as_hash = true
  db.execute('SELECT username,nickname FROM rcontact').each  do |row|
    username = row['username']
    nickname = row['nickname']
    if nickname != ''
      if username =~ /@chatroom$/
        talker2name[username] = nickname == '' ? username : nickname
      else
        username2name[username] = nickname == '' ? username : nickname
      end
    end
  end


  db.execute("select memberlist from chatroom where chatroomname='3783139122@chatroom'").each do |row|
    memberlist = row['memberlist']
    memberlist.split(/;/).each do |wxid|
      name=username2name.fetch(wxid, 'xxxx')    
      Member.new(wxid: wxid, name: name).save
    end   
  end


  db.execute("SELECT createTime,talker,content FROM message where talker='3783139122@chatroom'").each do |row|
    time,talker,content = row.values_at 'createTime','talker','content'
    next unless content
    next if(Time.now - Time.at(time/1000) > 60*60*24*14 )   
    next if content =~ /关键字/       #skip. 这个消息是群主发通告。打卡不应该包含“关键字”。
    next if content =~ /微信红包/       #skip.     
    next if content =~ /^~SEMI_XML~/  
    if content.match('#打卡')           
      id=content.scan(/^(.+?):\n/)[0]? content.scan(/^(.+?):\n/)[0][0]:"chenxing_2489"         # if the id is empty then it is me
      puts id
      #name = talker2name.fetch talker, talker
      
      activity_stat[id]+=1
      content.sub!(/^#{id}:\n/) {|x| "" }
      workaout=Workout.new(wxid: id, name: name, time: Time.at(time/1000).strftime('%F %R',detail: content )
      workout.save                           
    end
  end
  end
end
end
