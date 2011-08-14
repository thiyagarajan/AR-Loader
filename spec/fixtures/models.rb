
class Project < ActiveRecord::Base
  has_many :milestones

  has_many :releases
  has_many :versions, :through => :releases
  
  has_and_belongs_to_many :categories

end

class Milestone < ActiveRecord::Base
  belongs_to :project

  #validate the name, cost
end

# had_and_belongs to join table
class Category < ActiveRecord::Base
  has_and_belongs_to_many :projects
end


class Version < ActiveRecord::Base
  has_many :releases
end

# Join Table with additional columns
class Release < ActiveRecord::Base
  belongs_to :project
  belongs_to :version

  #validate the name
end
