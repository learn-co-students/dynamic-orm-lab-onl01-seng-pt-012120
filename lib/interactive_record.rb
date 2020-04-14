require_relative "../config/environment.rb"
require 'active_support/inflector'
require 'pry'


class InteractiveRecord
  
  def self.table_name
    self.to_s.downcase.pluralize
  end
  
  def self.column_names
    DB[:conn].results_as_hash = true
    
    sql = "PRAGMA table_info (#{table_name})"
    table_info = DB[:conn].execute(sql)
    column_names = []
    
    table_info.each do |column|
      column_names << column["name"]
    end
    column_names.compact
  end
  
  def initialize(options ={})
    options.each do |property, value|
      self.send("#{property}=", value)
    end
  end
  
  def table_name_for_insert
    self.class.table_name
  end
  
  def col_names_for_insert
    self.class.column_names.delete_if {|col| col == "id"}.join(", ")
  end
  
  def values_for_insert
    values = []
    
    self.class.column_names.each do |col|
      values << "'#{send(col)}'" unless send(col).nil?
    end
    values.join(", ")
  end
  
  def save
    sql = <<-SQL
    INSERT INTO #{table_name_for_insert} (#{col_names_for_insert})
    VALUES (#{values_for_insert})
    SQL
    
    DB[:conn].execute(sql)
    @id = DB[:conn].execute("SELECT last_insert_rowid() FROM #{table_name_for_insert}")[0][0]
  end
  
  def self.find_by_name(name)
    DB[:conn].execute("SELECT * FROM #{self.table_name} WHERE name = ?", [name])
  end
  
  def self.find_by(attributes)
    attributes_key = attributes.keys[0]
    attributes_value = attributes.values[0]
    
    sql = <<-SQL
    SELECT * FROM #{self.table_name} 
    WHERE #{attributes_key} = '#{attributes_value}'
    SQL
    
    DB[:conn].execute(sql)
  end
  
end
