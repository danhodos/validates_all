module DanHodos #:nodoc:
  module ActiveRecord #:nodoc:
    module ValidatesAll #:nodoc:
      module ClassMethods #:nodoc:
        # Validates all the attributes against a block.
        #
        #   class Person < ActiveRecord::Base
        #     validates_all :security_answer_1, :security_answer_2 do |record, attrs, values|
        #       message = '#{attrs.to_sentence(:connector => 'or')} must be set'
        #       record.errors.add_to_base(message) if attrs.all?(&:blank?)
        #     end
        #   end
        #
        # Options:
        # * <tt>on</tt> - Specifies when this validation is active (default is :save, other options :create, :update)
        # * <tt>if</tt> - Specifies a method, proc or string to call to determine if the validation should
        # occur (e.g. :if => :allow_validation, or :if => Proc.new { |user| user.signup_step > 2 }).  The
        # method, proc or string should return or evaluate to a true or false value.
        def validates_all(*attrs)
          options = attrs.last.is_a?(Hash) ? attrs.pop.symbolize_keys : {}
          attrs = attrs.flatten
          
          send(validation_method(options[:on] || :save)) do |record|
            unless options[:if] && !evaluate_condition(options[:if], record)
              values = attrs.map {|attr| record.send(attr) }
              yield record, attrs, values
            end
          end
        end
        
        # Validates that at least one of the specified attributes are not blank (as defined by Object#blank?). 
        # Happens by default on save. Example:
        #
        #   class Person < ActiveRecord::Base
        #     validates_presence_of_one_of :email_address, :login_name
        #   end
        #      
        # Configuration options are the same as validates_all.
        def validates_presence_of_one_of(*attrs)
          overrides = attrs.pop if attrs.last.is_a?(Hash)
          configuration = {
            :message => "#{attrs.map {|attr| attr.to_s.humanize }.to_sentence(:connector => 'or')} must be specified", 
            :on => :save }
          configuration.update(overrides) if overrides
          
          validates_all(attrs, configuration) do |record, attributes, values|
            record.errors.add_to_base(configuration[:message]) if values.all?(&:blank?)
          end
        end
        
        # An alias for validates_presence_of_either
        alias_method :validates_presence_of_either, :validates_presence_of_one_of
        
        # Validates that each of the specified attributes have a different value.
        #
        #   class Person < ActiveRecord::Base
        #     validates_different :best_friend_id, :second_best_friend_id
        #   end
        #      
        # # Configuration options are the same as validates_all, plus:
        # * <tt>suppress_on_blanks</tt> - Prevents any error from being triggered if all attributes are blank.
        def validates_different(*attrs)
          overrides = attrs.pop if attrs.last.is_a?(Hash)
          configuration = {
            :message => "#{attrs.first.to_s.humanize} cannot be the same as " + 
              "#{attrs[1,attrs.length].map {|attr| attr.to_s.humanize }.to_sentence}", 
            :on => :save }
          configuration.update(overrides) if overrides
          
          validates_all(attrs, configuration) do |record, attributes, values|
            unless configuration[:suppress_on_blanks] && values.all?(&:blank?)
              record.errors.add_to_base(configuration[:message]) if values.uniq.length == 1
            end
          end
        end
      end # ClassMethods
    end # ValidatesAll
  end # ActiveRecord
end # DanHodos

ActiveRecord::Base.extend(DanHodos::ActiveRecord::ValidatesAll::ClassMethods)