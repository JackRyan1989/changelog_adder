#!/usr/bin/env ruby

require 'open3'
require 'tty-prompt'

class AddChangelog
    attr_reader :message

    def initialize
        @prompt = TTY::Prompt.new
    end

    CATEGORIES = [
        'User-Facing Improvements',
        'Bug Fixes',
        'Internal',
        'Upcoming Features'
    ].freeze

    TEXT_VALIDATION = %r{[\w -]{2,}}

    CHANGELOG_MESSAGE_REGEX =
      %r{^(?:\* )?changelog: ?(?<category>[\w -]{2,}), ?(?<subcategory>[^,]{2,}), ?(?<change>.+)$}i

    CHANGELOG_REGEX = Regexp.new('changelog')
    BASE_BRANCH = 'main'
    SOURCE_BRANCH = 'HEAD'
    CHANGELOG_EXISTS_MSG = 'Hey, a changelog already exists for this branch. You should deal with that manually using git.'
    REDO_CHANGELOG = 'The changelog you created is invalid. Please make a new one.'
    
    # @param base_branch: String
    # @param source_branch: String
    # @return array
    def make_git_log(base_branch, source_branch)
      format = '--pretty=title: %s%nbody:%b%nDELIMITER'
      begin
        log, err, status = Open3.capture3(
          'git', 'log', format, "#{base_branch}..#{source_branch}"
        )
      rescue
        raise 'git log failed' unless status.success?
      end
      log
    end

    def perform_commit
      git_commands = 'commit --allow-empty -m'
      begin
        output, status = Open3.capture2(
          'git', :stdin_data => git_commands
        )
      rescue
        raise 'git commit failed' 
      end
    end

    def commit_to_commit?
      @prompt.yes?("Commit changelog?")
    end
    
    # @return Boolean
    def changelog_exists?
      log = make_git_log(BASE_BRANCH, SOURCE_BRANCH)
      CHANGELOG_REGEX.match?(log)
    end

    def get_category
        @category = @prompt.select("Select Category:", CATEGORIES, cycle: true) do | q |
            q.enum "."
        end
    end

    def get_subcategory
        @subcategory = @prompt.ask("Provide a Subcategory:", default: 'In-Person Proofing') do | q |
            q.required true
            q.modify :trim
            q.validate(TEXT_VALIDATION)
        end
    end

    def get_explanation
        @explanation = @prompt.ask("Provide an Explanation:") do | q |
            q.required true
            q.modify :trim
            q.validate(TEXT_VALIDATION)
        end
    end

    def construct_changelog
      get_category
      get_subcategory
      get_explanation
      @message = "changelog: #{@category}, #{@subcategory}, #{@explanation}"
    end

    def redo_changelog?
      @redo = @prompt.yes?("Redo changelog?")
    end

    def message_valid?
      CHANGELOG_MESSAGE_REGEX.match?(@message)
    end

    # @return nil
    def compose_message
      if changelog_exists?
        puts CHANGELOG_EXISTS_MSG
        return
      end
      construct_changelog
      unless message_valid?
        puts REDO_CHANGELOG
        if redo_changelog? 
          compose_message
        else
          @message = nil
        end
      end
    end
end 

def main
    log = AddChangelog.new()
    log.compose_message
    puts "\n"
    puts log.message
    puts "\n"
    log.perform_commit unless !log.commit_to_commit?
end

main