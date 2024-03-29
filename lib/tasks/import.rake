# coding: utf-8

require 'sqlite3'
require 'kramdown'

desc "import 打卡记录"
task :import, [:filename] => :environment do    
  begin
    talker2name = {}
    username2name = {}
    activity_stat={}

    db = SQLite3::Database.open './lib/tasks/decrypted_database.db'
    #db = SQLite3::Database.open './lib/tasks/decrypted_database.db_s5_backup'
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
        member=Member.where(wxid: wxid).first_or_create 
        member.name=name
        member.save      
      end
      currentMembers=memberlist.split(/;/)
      Member.all.each do |member|
        unless currentMembers.include?(member.wxid)
          puts "destroy:#{member.name} #{member.wxid}"
          member.destroy          
        end
      end
      
    end

    newRecord=false
    db.execute("SELECT msgId,msgSvrId, createTime,talker,content FROM message where talker='3783139122@chatroom'").each do |row|
      msgId,msgSvrId, time,talker,content = row.values_at 'msgId','msgSvrId','createTime','talker','content'
      next unless content
     # next if(Time.now - Time.at(time/1000) > 60*60*24*14 )   
      next if content =~ /关键字/       #skip. 这个消息是群主发通告。打卡不应该包含“关键字”。
      next if content =~ /微信红包/       #skip.
      next if content =~ /建议/          #skip.
      next if content =~ /^~SEMI_XML~/  
      if content.match('#打卡') or content.match('＃打卡') 
        id=content.scan(/^(.+?):\n/)[0]? content.scan(/^(.+?):\n/)[0][0]:"chenxing_2489"         # if the id is empty then it is me
        name = talker2name.fetch talker, talker
        
 
        content.sub!(/^#{id}:\n/) {|x| "" }
        unless Workout.exists?(msgSvrId: msgSvrId)
          puts "#{time} #content"
          workout=Workout.new(msgSvrId: msgSvrId, wxid: id, name: name, time: Time.at(time/1000).strftime('%F %R'),detail: content ) 
          workout.save
          puts "#{workout.time} #{workout.name} #{workout.detail}"
          newRecord=true
        end        

      end
    end
    if newRecord
      exit 0
    else
      exit 100
    end
  rescue => exception
    puts exception.backtrace
    raise # always reraise
  end
  
end


desc "Generate the html"
task :export, [:filename] => :environment do

  period=14 
  output =  "# Notice \n\n"
  output <<  "* 打卡请包含关键字 *#打卡*. 在群里面打卡的例子: *#打卡 跑步10公里*  \n"
  output <<  "* 统计周期为#{period}天 \n"
  output <<  "\n"
  
  output <<  "# Activities statistics of Last #{period} days (Updated on #{Time.now})  \n\n"
  output <<  "| Name |Times| \n"

  activity_stat=Member.all.inject({}) do |all, member|
    all[member]=Workout.where(wxid: member.wxid, time: (Time.now-60*60*24 * period)..(Time.now+24*3600)).select do |wk|
       wk.time.to_i > 1479427202 #2016/11/18                                                                                                                             
    end.size    
    all
  end
  activity_stat.sort_by{|k,v| v}.reverse.each do |record|    
    
    name=record[0].name
    if record[0].nick && record[0].nick.empty? == false
      name=record[0].nick
    end
    next if name=='Robot'
    output<< "|#{name} |#{record[1]} | \n "
  end

  output <<  "\n# Activities detail \n\n"
  activity_stat.sort_by{|k,v| v}.reverse.each do |record|
    member=record[0]
    next if record[1]==0 || member.name=='Robot'
    name=record[0].name
    if record[0].nick && record[0].nick.empty? == false    
      name=record[0].nick
    end
    output <<  "## [#{name}](history/#{member.wxid}.html) \n\n"
    Workout.where(wxid: member.wxid, time: (Time.now-60*60*24*period)..(Time.now+24*3600)).select{|wk| wk.time.to_i > 1479427202 }.each do |workout| 
      output <<  " #{workout.time} #{workout.detail} \n\n"
    end
  end

  # add full record

  activity_stat.sort_by{|k,v| v}.reverse.each do |record|
    member=record[0]
    next if member.name=='Robot'
    name=record[0].name
    if record[0].nick && record[0].nick.empty? == false    
      name=record[0].nick
    end
    all_records =  "# #{name} \n\n"
    lasttime=Time.now - 60*60*31*12*100   #100 years ago
    Workout.where(wxid: member.wxid).order('time DESC').each do |workout|
      if workout.time.month!=lasttime.month
        all_records << "## #{workout.time.strftime "%Y-%m"}\n"
      end
      all_records <<  " #{workout.time} #{workout.detail} \n\n"
      lasttime=workout.time
    end
    File.open("history/#{member.wxid}.html", 'w') { |file|  file.write( '<meta charset="utf-8"> <meta http-equiv="Cache-Control" content="no-cache, no-store, must-revalidate" /> <meta http-equiv="Pragma" content="no-cache" /> <meta http-equiv="Expires" content="0" />' +  Kramdown::Document.new(all_records).to_html) }
  end

  output <<  "# Source code \n\n"
  output <<  " [https://github.com/mingoc/wechat-group-stat](https://github.com/mingoc/wechat-group-stat)"

  
  File.open('stat.html', 'w') { |file|  file.write( '<meta charset="utf-8"> <meta http-equiv="Cache-Control" content="no-cache, no-store, must-revalidate" /> <meta http-equiv="Pragma" content="no-cache" /> <meta http-equiv="Expires" content="0" />' +  Kramdown::Document.new(output).to_html) }




  
end


