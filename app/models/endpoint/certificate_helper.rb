require 'openssl'
require 'socket'

class Endpoint::CertificateHelper
  # TODO: interaction with http_proxy_uri ?
  def self.unverified_server_cert_chain(hostname, port)
    # TODO: go through restclient?  e.g. it configures different ciphers than openssl.
    tcp_client = TCPSocket.new(hostname, port)
    ssl_context = OpenSSL::SSL::SSLContext.new
    ssl_context.verify_mode = OpenSSL::SSL::VERIFY_NONE
    ssl_client = OpenSSL::SSL::SSLSocket.new(tcp_client, ssl_context)
    ssl_client.hostname = hostname # Sent via SNI to get right cert back.
    ssl_client.connect
    # TODO: post_connection_check ?  not here, we *want* no verification
    ssl_client.peer_cert_chain
  ensure
    ssl_client.try(:close)
    tcp_client.try(:close)
  end

  def self.chain_info(cert_chain)
    root = root_cert_from_chain(cert_chain)
    {
      :root_issuer => (root || cert_chain.last).issuer.to_s,
      :root_fingerprint_sha256 => root && cert_fingerprint_sha256(root),
      :issued_to => cert_subjects_summary(cert_chain.first),
      # Intersect validity ranges along chain.
      :valid_from => cert_chain.collect(&:not_before).max,
      :valid_to => cert_chain.collect(&:not_after).min,
      :root_pem => root.try(:to_pem),
    }
  end

  def self.root_cert_from_chain(cert_chain)
    # Self-signed root cert, IF included, is normally last (http://serverfault.com/a/476620/44183)
    # This deals with any order.
    cert_chain.detect { |cert| self_signed?(cert) } if cert_chain
  end

  def self.self_signed?(cert)
    cert.subject == cert.issuer
  end

  def self.cert_summary(cert)
    # TODO translation
    if self_signed?(cert)
      "Self-signed by: #{cert.issuer}, SHA256 fingerprint: #{cert_fingerprint_sha256(cert)}"
    else
      "Issued by: #{cert.issuer}, Issued to: #{cert_subjects_summary(cert)}, Valid from #{} to #{cert.not_after}"
    end
  end

  def self.cert_subjects_summary(cert)
    subjects = cert.extensions.select { |ext| ext.oid == "subjectAltName" }.collect_concat { |ext| ext.value.split(/,\s*/) }
    subjects = cert.subject.to_s if subjects.empty?
    subjects
  end

  def self.cert_fingerprint_sha256(cert)
    fp = Digest::SHA256.hexdigest(cert.to_der)
    # Format AB:12:CD like `openssl x509 -fingerprint -sha256`.
    fp.scan(/../).join(':').upcase
  end
end
