require 'md5'
require 'uri'

module Rapleaf

  class Base

    def initialize(api_key, options = {})
      options = {
                  :api_host     => API_HOST,
                  :api_port     => API_PORT,
                  :api_version  => API_VERSION
                }.merge(options)

      @api_key  = api_key
      @host     = options[:api_host]
      @port     = options[:api_port]
      @version  = options[:api_version]
    end

    # This resource is used to retrieve information about a person, identified
    # using an email address or email address hash.
    # Examples:
    #  person(:email => 'dummy@rapleaf.com')
    #  person(:site => :twitter, :profile => 'samstokes')
    #  person(:sha1 => SHA1.hexdigest('dummy@rapleaf.com'))
    #  person(:md5 => MD5.hexdigest('dummy@rapleaf.com'))
    def person( opts = {} )
      resp = Net::HTTP.get_response(URI.parse(person_url(opts)))

      case resp.code
      when '200'
        return Response.parse(:xml => resp.body)
      when '202'
        raise PersonAccepted, 'This person is currently being searched. Check back shortly and we should have data.'
      when '400'
        raise PersonBadRequestInvalidEmail, 'Invalid email address.'
      when '401'
        raise AuthFailure, 'API key was not provided or is invalid.'
      when '403'
        raise ForbiddenQueryLimitExceeded, 'Your query limit has been exceeded. Contact developer@rapleaf.com if you would like to increase your limit.'
      when '404'
        raise PersonEmailHashNotFound, 'We do not have this email in our system and are not able to create a person using a hash. If you would like better results, consider supplying the unhashed email address.'
      when '500'
        raise InternalServerError, 'There was an unexpected error on our server. This should be very rare and if you see it please contact developer@rapleaf.com.'
      else
        msg = resp.body[0,50]
        msg << "..." if 50 < resp.body.length
        raise Error, %(Unexpected response code #{resp.code}: "#{msg}")
      end
    end

  private
    def person_url(opts)
      email = opts[:email]

      site_profile = [opts[:site], opts[:profile]]
      if site_profile.any?
        raise ArgumentError, 'Require both :site and :profile if either is specified' unless site_profile.all?
      else
        site_profile = nil
      end

      md5 = opts[:md5]
      sha1 = opts[:sha1]

      # Rapleaf requires email addresses be urlencoded
      # Pass our own "unsafe regex" as URI.escape's default is too permissive
      # (lets + through, but Rapleaf rejects it)
      email = URI.escape(email, /[^a-zA-Z0-9.\-_]/) if email

      selector = [email, site_profile, md5, sha1].compact
      raise ArgumentError, 'Please provide only one of :email, [:site and :profile], :md5 or :sha1' if selector.size > 1
      raise ArgumentError, 'Person selector must be provided' if selector.empty? || '' == selector[0]

      case @version
      when "v2"
        if site_profile
          raise ArgumentError, 'Query by website ID requires API v3 or greater'
        end
        person_url_v2_by_email_or_hash(email_or_hash[0])
      when "v3"
        if email
          person_url_v3_by_email(email)
        elsif site_profile
          person_url_v3_by_site_profile(*site_profile)
        elsif md5
          person_url_v3_by_hash(:md5, md5)
        else
          person_url_v3_by_hash(:sha1, sha1)
        end
      else
        raise ArgumentError, "Person queries not supported for API version #{@version}"
      end
    end

    def person_url_v2_by_email_or_hash(email_or_hash)
      "http://#{@host}:#{@port}/v2/person/#{email_or_hash}?api_key=#{@api_key}"
    end

    def person_url_v3_by_email(email)
      "http://#{@host}:#{@port}/v3/person/email/#{email}?api_key=#{@api_key}"
    end

    def person_url_v3_by_site_profile(site, profile)
      # TODO validate param formats
      "http://#{@host}:#{@port}/v3/person/web/#{site}/#{profile}?api_key=#{@api_key}"
    end

    def person_url_v3_by_hash(algo, hash)
      "http://#{@host}:#{@port}/v3/person/hash/#{algo}/#{hash}?api_key=#{@api_key}"
    end

  end

end
