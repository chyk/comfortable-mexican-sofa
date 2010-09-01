class CmsPage < ActiveRecord::Base
  
  acts_as_tree :counter_cache => :children_count
  
  # -- Relationships --------------------------------------------------------
  belongs_to :cms_layout
  has_many :cms_blocks, :dependent => :destroy
  accepts_nested_attributes_for :cms_blocks
  
  # -- Callbacks ------------------------------------------------------------
  before_validation :assign_full_path
  after_save        :sync_child_pages
  
  # -- Validations ----------------------------------------------------------
  validates :label,
    :presence   => true
  validates :slug,
    :presence   => true,
    :format     => /^\w[a-z0-9_-]*$/i,
    :unless     => lambda{ |p| p == CmsPage.root || CmsPage.count == 0 }
  validates :cms_layout,
    :presence   => true
  validates :full_path,
    :presence   => true,
    :uniqueness => true
  
  # -- Instance Methods -----------------------------------------------------
  # Scans through the content defined in the layout and replaces tag signatures
  # with content defined in cms_blocks, or whatever tag's render method does
  def render_content
    content = cms_layout.content.dup
    initialize_tags.each do |tag|
      content.gsub!(tag.regex_tag_signature){ tag.render }
    end
    return content
  end
  
  # Returns an array of tag objects, at the same time populates cms_blocks
  # of the current page
  def initialize_tags
    CmsTag.initialize_tags(self)
  end
  
protected
  
  def assign_full_path
    self.full_path = self.parent ? "#{self.parent.full_path}/#{self.slug}".squeeze('/') : '/'
  end
  
  def sync_child_pages
    children.each{ |p| p.save! } if full_path_changed?
  end
  
end
