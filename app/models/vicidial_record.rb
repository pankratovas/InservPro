class VicidialRecord < ApplicationRecord
  self.abstract_class = true
  connects_to database: { writing: :vicidial }
end



