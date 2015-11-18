# File-writing code is from the store report processor in puppet's master branch.
# The rest of the code is from the puppetdb report processor in puppetdb's 2.3.x branch.
require 'puppet'

Puppet::Reports.register_report(:puppetdb_file) do
  desc <<-DESC
  Save report information to a file for sending to PuppetDB via the REST API
later.  Reports are serialized to JSON format and may then submitted to puppetdb.
  DESC

  # Process the report by formatting it into a PuppetDB 'store report'
  # written to disk to be submitted to PuppetDB later.
  #
  # @return [void]
  def process
    dir = File.join(Puppet[:reportdir], host)
    if ! Puppet::FileSystem.exist?(dir)
      FileUtils.mkdir_p(dir)
      FileUtils.chmod_R(0750, dir)
    end
    now = Time.now.gmtime
    name = %w{year month day hour min}.collect do |method|
      "%02d" % now.send(method).to_s
    end.join("") + "_puppetdb.json"
    file = File.join(dir, name)
    begin
      Puppet::Util.replace_file(file, 0640) do |fh|
        fh.print({ "command" => "store report", "version" => 3, "payload" => report_to_hash }.to_json)
      end
    rescue => detail
       Puppet.log_exception(detail, "Could not write report for #{host} at #{file}: #{detail}")
    end

    nil
  end

  # Convert `self` (an instance of `Puppet::Transaction::Report`) to a hash
  # suitable for sending over the wire to PuppetDB
  #
  # @return Hash[<String, Object>]
  # @api private
  def report_to_hash
    if environment.nil?
      raise Puppet::Error, "Environment is nil, unable to submit report. This may be due a bug with Puppet. Ensure you are running the latest revision, see PUP-2508 for more details."
    end

    {
      "certname"              => host,
      "puppet-version"        => puppet_version,
      "report-format"         => report_format,
      "configuration-version" => configuration_version.to_s,
      "start-time"            => time.iso8601(9),
      "end-time"              => (time + run_duration).iso8601(9),
      "resource-events"       => build_events_list,
      "environment"           => environment,
      "transaction-uuid"      => transaction_uuid,
      "status"                => status,
    }
  end

  # Build a resource-events array from both evaluated and skipped resources.
  #
  # @return Array[Hash]
  # @api private
  def build_events_list
    resource_statuses.inject([]) do |events, status_entry|
      _, status = *status_entry
      if ! (status.events.empty?)
        events.concat(status.events.map { |event| event_to_hash(status, event) })
      elsif status.skipped
        events.concat([fabricate_event(status, "skipped")])
      end
      events
    end
  end

  # Calculate run duration.
  #
  # @return Number
  # @api private
  def run_duration
    if metrics["time"] and metrics["time"]["total"]
      metrics["time"]["total"]
    else
      0
    end
  end

  # Convert an instance of `Puppet::Transaction::Event` to a hash
  # suitable for sending over the wire to PuppetDB
  #
  # @return Hash[<String, Object>]
  # @api private
  def event_to_hash(resource_status, event)
    {
      "status"           => event.status,
      "timestamp"        => event.time.iso8601(9),
      "resource-type"    => resource_status.resource_type,
      "resource-title"   => resource_status.title.to_s,
      "property"         => event.property,
      "new-value"        => event.desired_value,
      "old-value"        => event.previous_value,
      "message"          => event.message,
      "file"             => resource_status.file,
      "line"             => resource_status.line,
      "containment-path" => resource_status.containment_path,
    }
  end

  # Given an instance of `Puppet::Resource::Status` and a status
  # string, this method fabricates a PuppetDB event object with the
  # provided `"status"`.
  #
  # @api private
  def fabricate_event(resource_status, event_status)
    {
      "status"           => event_status,
      "timestamp"        => resource_status.time.iso8601(9),
      "resource-type"    => resource_status.resource_type,
      "resource-title"   => resource_status.title.to_s,
      "property"         => nil,
      "new-value"        => nil,
      "old-value"        => nil,
      "message"          => nil,
      "file"             => resource_status.file,
      "line"             => resource_status.line,
      "containment-path" => resource_status.containment_path,
    }
  end
end
