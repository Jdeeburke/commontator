module Commontator
  class Comment < ActiveRecord::Base

    acts_as_votable

    belongs_to :commontator, :polymorphic => true
    belongs_to :deleter, :polymorphic => true
    belongs_to :thread
    
    has_one :commontable, :through => :thread
    #has_one :subthread, :class_name => "Thread",
    #                    :as => :commontable,
    #                    :dependent => :destroy

    before_validation :build_subthread, :on => :create
    validates_presence_of :commontator, :thread#, :subthread
    #validates_uniqueness_of :subthread

    attr_accessible :body
    
    def delete(user = nil)
      self.deleted_at = Time.now
      self.deleter = user
      self.save!
    end
    
    def undelete
      self.deleted_at = nil
      self.save!
    end

    def is_modified?
      updated_at != created_at
    end
    
    def is_deleted?
      !deleted_at.blank?
    end

    ##########################
    # Access control methods #
    ##########################

    def can_be_created_by?(user)
      !thread.is_closed? && thread.can_be_read_by?(user) && user == commontator
    end

    def can_be_edited_by?(user)
      !thread.is_closed? && !is_deleted? &&\
      ((user == commontator && thread.config.can_edit_own_comments) ||\
      (thread.can_be_edited_by?(user) && thread.config.admin_can_edit_comments)) &&\
      (thread.comments.last == self || thread.config.can_edit_old_comments)
    end

    def can_be_deleted_by?(user)
      !thread.is_closed? && !is_deleted? &&\
      ((user == commontator && thread.config.can_delete_own_comments) &&\
      (thread.comments.last == self || thread.config.can_delete_old_comments)) ||\
      thread.can_be_edited_by?(user)
    end
    
    def can_be_voted_on?
      thread.config.comments_can_be_voted_on
    end

    def can_be_voted_on_by?(user)
      can_be_voted_on? && !thread.is_closed? && !is_deleted? &&\
        thread.can_be_read_by?(user) && user != commontator
    end
    
  end
end