# frozen_string_literal: true

module EditionAssertions
  class Error < StandardError
    attr_reader :edition

    def initialize(edition, assertion)
      @edition = edition
      super("Assertion failed: #{assertion}")
    end
  end

  class StateError < Error
    def initialize(edition, assertion)
      super(edition, assertion || "meets state requirements")
    end
  end

  class AccessError < Error
    def initialize(edition, limit_type)
      super(edition, "user is in #{limit_type}")
    end
  end

  def assert_edition_state(edition, options = {}, &block)
    return if block.call(edition)

    assertion = options[:assertion]
    assertion ||= block.to_s if block.to_s =~ /&:/ # &:editable?
    raise StateError.new(edition, assertion)
  end

  def assert_edition_access(edition, user)
    return unless edition.access_limit

    org_id = user.organisation_content_id
    access_limit = edition.access_limit

    return if org_id == edition.primary_publishing_organisation_id

    return if access_limit.all_organisations? &&
      edition.organisations.include?(org_id)

    raise AccessError.new(edition, access_limit.limit_type)
  end
end