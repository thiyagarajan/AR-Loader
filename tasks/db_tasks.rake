namespace :autotelik do

  namespace :db  do

    SYSTEM_TABLE_EXCLUSION_LIST = ['schema_migrations']

    desc "Purge the current database"
    task :purge, :exclude_system_tables, :needs => [:environment] do |t, args|
      require 'highline/import'

      if(RAILS_ENV == 'production')
        agree("WARNING: In Production database, REALLY PURGE ? [y]:")
      end

      config = ActiveRecord::Base.configurations[RAILS_ENV || 'development']
      case config['adapter']
      when "mysql", "jdbcmysql"
        ActiveRecord::Base.establish_connection(config)
        ActiveRecord::Base.connection.tables.each do |table|
          next if(args[:exclude_system_tables] && SYSTEM_TABLE_EXCLUSION_LIST.include?(table) )
          puts "purging table: #{table}"
          ActiveRecord::Base.connection.execute("TRUNCATE #{table}")
        end
      when "sqlite","sqlite3"
        dbfile = config["database"] || config["dbfile"]
        File.delete(dbfile) if File.exist?(dbfile)
      when "sqlserver"
        dropfkscript = "#{config["host"]}.#{config["database"]}.DP1".gsub(/\\/,'-')
        `osql -E -S #{config["host"]} -d #{config["database"]} -i db\\#{dropfkscript}`
        `osql -E -S #{config["host"]} -d #{config["database"]} -i db\\#{RAILS_ENV}_structure.sql`
      when "oci", "oracle"
        ActiveRecord::Base.establish_connection(config)
        ActiveRecord::Base.connection.structure_drop.split(";\n\n").each do |ddl|
          ActiveRecord::Base.connection.execute(ddl)
        end
      when "firebird"
        ActiveRecord::Base.establish_connection(config)
        ActiveRecord::Base.connection.recreate_database!
      else
        raise "Task not supported by '#{config["adapter"]}'"
      end
    end
  end
end