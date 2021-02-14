class Auth0::Log
  include ActiveModel::Serialization
  
  attr_accessor :type, :format, :user, :group, :message, :date
  
  PAGE_LIMIT = 100
  
  def initialize(attrs)
    attrs = attrs.with_indifferent_access
    @type = attrs['type']
    @format = attrs['format']
    @user = attrs['user']
    @group = attrs['group']
    @message = attrs['message']
    @date = attrs['date']
  end
  
  def self.create(opts)
    log_id = SecureRandom.hex(8)
    
    PluginStore.set(Auth0::PLUGIN_NAME,
      "log_#{log_id}",
      opts.merge(date: Time.now)
    )
  end
  
  def self.list_query(type)
    PluginStoreRow.where("
      plugin_name = '#{Auth0::PLUGIN_NAME}' AND
      key LIKE 'log_%' AND
      (value::json->'date') IS NOT NULL
    ").order("value::json->>'date' DESC")
  end
  
  def self.add_filter_query(attr, value)
    "AND "
  end
  
  def self.list(page: 0, filter: '', type: 'group_membership')
    list = list_query(type)
    
    if filter
      list = list.where("
        value::json->>'user' ~ '#{filter}' OR
        value::json->>'group' ~ '#{filter}'
      ")
    end
    
    list.limit(PAGE_LIMIT)
      .offset(page * PAGE_LIMIT)
      .map { |r| self.new(JSON.parse(r.value)) }
  end
end