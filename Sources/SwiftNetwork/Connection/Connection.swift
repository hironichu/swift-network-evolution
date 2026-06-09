//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift open source project
//
// Copyright (c) 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Swift project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

#if canImport(BasicContainers)
import BasicContainers
internal import DequeModule
#endif

#if canImport(Glibc)
import Glibc
internal import Logging
#elseif canImport(os)
internal import os
#endif

#if canImport(Synchronization)
internal import Synchronization
#endif

@_spi(Essentials)
@available(Network 0.1.0, *)
public protocol NetworkFixedWidthInteger: FixedWidthInteger {
    init(bigEndian: Self)
    var bigEndian: Self { get }
}

@_spi(Essentials)
@available(Network 0.1.0, *)
extension UInt8: NetworkFixedWidthInteger {}

@_spi(Essentials)
@available(Network 0.1.0, *)
extension UInt16: NetworkFixedWidthInteger {}

@_spi(Essentials)
@available(Network 0.1.0, *)
extension UInt32: NetworkFixedWidthInteger {}

@_spi(Essentials)
@available(Network 0.1.0, *)
extension UInt64: NetworkFixedWidthInteger {}

@_spi(Essentials)
@available(Network 0.1.0, *)
extension Int8: NetworkFixedWidthInteger {}

@_spi(Essentials)
@available(Network 0.1.0, *)
extension Int16: NetworkFixedWidthInteger {}

@_spi(Essentials)
@available(Network 0.1.0, *)
extension Int32: NetworkFixedWidthInteger {}

@_spi(Essentials)
@available(Network 0.1.0, *)
extension Int64: NetworkFixedWidthInteger {}

@_spi(Essentials)
@available(Network 0.1.0, *)
public protocol ConnectionProtocol: Identifiable, Hashable {
    associatedtype ApplicationProtocolType: NetworkProtocolOptions
}

/// A protocol stack configuration option.
///
/// Conforming types can be used when configuring protocol stacks.
@_spi(Essentials)
@available(Network 0.1.0, *)
public protocol NetworkMetadataProtocol {
}

@_spi(Essentials)
@available(Network 0.1.0, *)
public protocol NetworkProtocolOptions {
    associatedtype BelowProtocol
    associatedtype ProtocolStorage: ConnectionStorage = DefaultProtocolStorage
    typealias Message<T> = T

    var belowProtocol: BelowProtocol { get }

    func configure(parameters: Parameters)
}

extension NetworkProtocolOptions {
    public var belowProtocol: BelowProtocol {
        fatalError("This should not be called")
    }

    func configure(parameters: Parameters) {
        fatalError("This should not be called")
    }
}

/// Additional storage attached to a connection.
///
/// Conforming types can be used as additional storage within a connection.
@_spi(Essentials)
@available(Network 0.1.0, *)
public protocol ConnectionStorage {
    init()
}

@_spi(Essentials)
@available(Network 0.1.0, *)
public struct DefaultProtocolStorage: ConnectionStorage, Sendable {
    public init() {}
}

/// A protocol that can sit at the top of a non-multiplexed connection's protocol stack.
///
/// Conforming types are allowed to be the top protocol in a network protocol stack
/// for non-multiplexed connections.
@_spi(Essentials)
@available(Network 0.1.0, *)
public protocol OneToOneProtocol: NetworkProtocolOptions {
}

/// A protocol that can sit at the top of a multiplexed connection's protocol stack.
///
/// Conforming types are allowed to be the top protocol in a network protocol stack
/// for multiplexing network connection objects. Generally, network protocols
/// conforming to this type don't directly expose send or receive methods.
/// Instead, they expose methods to open and listen for multiplexed subconnections,
/// which can send and receive.
@_spi(Essentials)
@available(Network 0.1.0, *)
public protocol MultiplexProtocol: NetworkProtocolOptions {
}

/// A protocol that exposes byte-stream send and receive methods.
///
/// Conforming types expose methods for sending and receiving byte streams.
@_spi(Essentials)
@available(Network 0.1.0, *)
public protocol StreamProtocol: OneToOneProtocol {
}

@_spi(Essentials)
@available(Network 0.1.0, *)
extension StreamProtocol {
}

/// A protocol that sends and receives messages.
///
/// Conforming types send and receive messages. The conforming type is responsible for
/// specifying its message-specific metadata.
@_spi(Essentials)
@available(Network 0.1.0, *)
public protocol MessageProtocol: OneToOneProtocol {
    associatedtype ContentType
}

/// A protocol that sends and receives small, bounded messages.
///
/// Conforming types send and receive messages with minimal or no metadata,
/// usually constrained to a fixed maximum size.
@_spi(Essentials)
@available(Network 0.1.0, *)
public protocol DatagramProtocol: MessageProtocol {
}

/// A result builder for specifying and configuring protocol stacks declaratively.
@_spi(Essentials)
@available(Network 0.1.0, *)
@resultBuilder
public struct ProtocolStackBuilder<ApplicationProtocol: NetworkProtocolOptions> {
    static public func buildBlock(_ applicationProtocol: ApplicationProtocol) -> (ApplicationProtocol) {
        (applicationProtocol)
    }
}

/// A type that produces parameters for a connection.
///
/// Conforming types can be used to generate a `Parameters` value.
@_spi(Essentials)
@available(Network 0.1.0, *)
public protocol ParametersProvider {
    /// The generated parameters.
    var parameters: Parameters { get set }

    /// Require an interface when connecting, listening, and browsing.
    ///
    /// Connections will fail if this interface is not available.
    ///
    /// - Parameter interface: The interface to require.
    func requiredInterface(_ interface: Interface) -> Self

    /// Require an interface type when connecting, listening, and browsing.
    ///
    /// - Parameter type: The interface type to require.
    func requiredInterfaceType(_ type: InterfaceType) -> Self

    /// Prohibit certain interfaces from being used to connect, listen, and browse.
    ///
    /// - Parameter interfaces: An array of interfaces to prohibit.
    func prohibitedInterfaces(_ interfaces: [Interface]) -> Self

    /// Prohibit certain interface types from being used to connect, listen, and browse.
    ///
    /// - Parameter types: An array of interface types to prohibit.
    func prohibitedInterfaceTypes(_ types: [InterfaceType]) -> Self

    /// Prohibit using expensive paths.
    ///
    /// Prohibit connections and listeners from using a network interface
    /// that is considered expensive by the system,
    /// for example, some cellular interfaces.
    ///
    /// - Parameter prohibited: `true` if expensive paths are prohibited, otherwise `false`.
    func expensivePathsProhibited(_ prohibited: Bool) -> Self

    /// Prohibit using constrained paths.
    ///
    /// Prohibit connections and listeners from using a network interface
    /// that is considered constrained by the system,
    /// for example an interface in Low Data Mode.
    ///
    /// - Parameter prohibited: `true` if constrained paths are prohibited, otherwise `false`.
    func constrainedPathsProhibited(_ prohibited: Bool) -> Self

    /// Specify a specific endpoint to use as the local endpoint.
    ///
    /// For connections, this is used to initiate traffic;
    /// for listeners, this is used for receiving incoming
    /// connections.
    ///
    /// - Parameter endpoint: The local endpoint to require, or `nil` if none.
    func localEndpoint(_ endpoint: Endpoint?) -> Self

    /// Specify a specific port to use as the local endpoint,
    /// letting the system select the address.
    ///
    /// For connections, this is used to initiate traffic;
    /// for listeners, this is used for receiving incoming
    /// connections.
    ///
    /// - Parameter port: The local port to require.
    func localPort(_ port: UInt16) -> Self

    /// Allow local endpoint reuse.
    ///
    /// Allow multiple connections to use the same local address and port
    /// (`SO_REUSEADDR` and `SO_REUSEPORT`).
    ///
    /// - Parameter allowed: `true` if allowed, otherwise `false`.
    func localEndpointReuseAllowed(_ allowed: Bool) -> Self

    /// Limit inbound connections to peers attached to the local link.
    ///
    /// Listeners only advertise services on the local link and
    /// only accept connections from the local link.
    ///
    /// - Parameter local: `true` if limited to local peers, otherwise `false`.
    func localOnly(_ local: Bool) -> Self

    /// Require DNSSEC validation when resolving an endpoint before making
    /// a connection.
    ///
    /// DNSSEC validation only takes effect if making a connection to an endpoint that
    /// requires domain name resolution, such as a host or URL endpoint.
    ///
    /// - If this is not set or is set to `false`, DNSSEC validation
    /// isn't required.
    ///
    /// - If this is set to `true` and no additional DNSSEC configuration
    ///	 is set, the default behavior is followed:
    ///	 only DNSSEC secure and DNSSEC insecure
    ///	 resolved results are used to establish a connection.
    ///
    /// - If this is set to `true` and additional DNSSEC configuration
    /// is set on the parameters, the behavior specified by that configuration is used.
    ///
    /// - Parameter required: `true` if DNSSEC validation is required, otherwise `false`.
    func dnssecValidationRequired(_ required: Bool) -> Self

    /// Set the data service class to use for connections.
    ///
    /// - Parameter serviceClass: The service class to use.
    func serviceClass(_ serviceClass: Parameters.ServiceClass) -> Self

    /// Set the multipath service to use for connections.
    ///
    /// - Parameter type: The multipath service type to use.
    func multipathServiceType(_ type: Parameters.MultipathServiceType) -> Self

    /// Allow fast open to be used on a connection.
    ///
    /// Use fast open for an outbound connection, which may be done at any protocol level.
    /// Use of fast open requires that the caller send idempotent data on the connection
    /// before the connection may move into the ready state.
    ///
    /// > Warning: This may have security implications for application data.
    /// In particular, TLS early data is replayable by a network attacker.
    /// You must account for this when sending data before the handshake
    /// is confirmed. See RFC 8446 for more information. Don't
    /// enable fast open without a specific application profile that defines its use.
    ///
    /// As a side effect, this may implicitly enable fast open or early data for protocols
    /// in the stack, even if they didn't have fast open explicitly enabled on them
    /// (such as the option to enable TCP Fast Open).
    ///
    /// - Parameter allowed: `true` if fast open should be used, otherwise `false`.
    func fastOpenAllowed(_ allowed: Bool) -> Self

    /// Allow or prohibit the use of expired DNS answers during connection establishment.
    ///
    /// If allowed, a DNS answer that was previously returned may be reused for new
    /// connections even after the answers are considered expired. A query for fresh answers
    /// is sent in parallel, and the fresh answers are used as alternate addresses
    /// in case the expired answers don't result in successful connections.
    ///
    /// By default, this value is `.systemDefault`, which allows the system to determine
    /// if it is appropriate to use expired answers.
    ///
    /// - Parameter behavior: The expired DNS behavior to use.
    func expiredDNSBehavior(_ behavior: Parameters.ExpiredDNSBehavior) -> Self

    func protocolListenerAttached(_ val: Bool) -> Self

    func parallelConnectionAttemptsProhibited(_ val: Bool) -> Self
}

@_spi(Essentials)
@available(Network 0.1.0, *)
extension ParametersProvider {
    /// Require an interface when connecting, listening, and browsing.
    ///
    /// - Parameter interface: The interface to require.
    public func requiredInterface(_ interface: Interface) -> Self {
        var mutableSelf = self
        mutableSelf.parameters.requiredInterface = interface
        return mutableSelf
    }

    /// Require an interface type when connecting, listening, and browsing.
    ///
    /// - Parameter type: The interface type to require.
    public func requiredInterfaceType(_ type: InterfaceType) -> Self {
        var mutableSelf = self
        mutableSelf.parameters.requiredInterfaceType = type
        return mutableSelf
    }

    public func requiredInterfaceSubtype(_ val: InterfaceSubtype) -> Self {
        var mutableSelf = self
        mutableSelf.parameters.requiredInterfaceSubtype = val
        return mutableSelf
    }

    /// Prohibit certain interfaces from being used to connect, listen, and browse.
    ///
    /// - Parameter interfaces: An array of interfaces to prohibit.
    public func prohibitedInterfaces(_ interfaces: [Interface]) -> Self {
        var mutableSelf = self
        mutableSelf.parameters.prohibitedInterfaces = Deque<Interface>(interfaces)
        return mutableSelf
    }

    /// Prohibit certain interface types from being used to connect, listen, and browse.
    ///
    /// - Parameter types: An array of interface types to prohibit.
    public func prohibitedInterfaceTypes(_ types: [InterfaceType]) -> Self {
        var mutableSelf = self
        mutableSelf.parameters.prohibitedInterfaceTypes = Deque<InterfaceType>(types)
        return mutableSelf
    }

    public func prohibitedInterfaceSubtypes(_ val: [InterfaceSubtype]) -> Self {
        var mutableSelf = self
        mutableSelf.parameters.prohibitedInterfaceSubtypes = Deque<InterfaceSubtype>(val)
        return mutableSelf
    }

    /// Prohibit using expensive paths.
    ///
    /// Prohibit connections and listeners from using a network interface
    /// that is considered expensive by the system,
    /// for example, some cellular interfaces.
    ///
    /// - Parameter prohibited: `true` if expensive paths are prohibited, otherwise `false`.
    public func expensivePathsProhibited(_ prohibited: Bool) -> Self {
        var mutableSelf = self
        mutableSelf.parameters.prohibitExpensivePaths = prohibited
        return mutableSelf
    }

    /// Prohibit using constrained paths.
    ///
    /// Prohibit connections and listeners from using a network interface
    /// that is considered constrained by the system,
    /// for example an interface in Low Data Mode.
    ///
    /// - Parameter prohibited: `true` if constrained paths are prohibited, otherwise `false`.
    public func constrainedPathsProhibited(_ prohibited: Bool) -> Self {
        var mutableSelf = self
        mutableSelf.parameters.prohibitConstrainedPaths = prohibited
        return mutableSelf
    }

    /// Specify a specific endpoint to use as the local endpoint.
    ///
    /// For connections, this is used to initiate traffic;
    /// for listeners, this is used for receiving incoming
    /// connections.
    ///
    /// - Parameter endpoint: The local endpoint to require, or `nil` if none.
    public func localEndpoint(_ endpoint: Endpoint?) -> Self {
        var mutableSelf = self
        mutableSelf.parameters.localAddress = endpoint
        return mutableSelf
    }

    /// Specify a specific port to use as the local endpoint,
    /// letting the system select the address.
    ///
    /// For connections, this is used to initiate traffic;
    /// for listeners, this is used for receiving incoming
    /// connections.
    ///
    /// - Parameter port: The local port to require.
    public func localPort(_ port: UInt16) -> Self {
        var mutableSelf = self
        mutableSelf.parameters.localAddress = Endpoint(hostname: "::", port: port)
        return mutableSelf
    }

    /// Allow local endpoint reuse.
    ///
    /// Allow multiple connections to use the same local address and port
    /// (`SO_REUSEADDR` and `SO_REUSEPORT`).
    ///
    /// - Parameter allowed: `true` if allowed, otherwise `false`.
    public func localEndpointReuseAllowed(_ allowed: Bool) -> Self {
        var mutableSelf = self
        mutableSelf.parameters.reuseLocalAddress = allowed
        return mutableSelf
    }

    /// Limit inbound connections to peers attached to the local link.
    ///
    /// Listeners only advertise services on the local link and
    /// only accept connections from the local link.
    ///
    /// - Parameter local: `true` if limited to local peers, otherwise `false`.
    public func localOnly(_ local: Bool) -> Self {
        var mutableSelf = self
        mutableSelf.parameters.localOnly = local
        return mutableSelf
    }

    /// Require DNSSEC validation when resolving an endpoint before making
    /// a connection.
    ///
    /// DNSSEC validation only takes effect if making a connection to an endpoint that
    /// requires domain name resolution, such as a host or URL endpoint.
    ///
    /// - If this is not set or is set to `false`, DNSSEC validation
    /// isn't required.
    ///
    /// - If this is set to `true` and no additional DNSSEC configuration
    ///	 is set, the default behavior is followed:
    ///	 only DNSSEC secure and DNSSEC insecure
    ///	 resolved results are used to establish a connection.
    ///
    /// - If this is set to `true` and additional DNSSEC configuration
    /// is set on the parameters, the behavior specified by that configuration is used.
    ///
    /// - Parameter required: `true` if DNSSEC validation is required, otherwise `false`.
    public func dnssecValidationRequired(_ required: Bool) -> Self {
        var mutableSelf = self
        mutableSelf.parameters.requiresDNSSECValidation = required
        return mutableSelf
    }

    /// Set the data service class to use for connections.
    ///
    /// - Parameter serviceClass: The service class to use.
    public func serviceClass(_ serviceClass: Parameters.ServiceClass) -> Self {
        var mutableSelf = self
        mutableSelf.parameters.serviceClass = serviceClass
        return mutableSelf
    }

    /// Set the multipath service to use for connections.
    ///
    /// - Parameter type: The multipath service type to use.
    public func multipathServiceType(_ type: Parameters.MultipathServiceType) -> Self {
        var mutableSelf = self
        mutableSelf.parameters.multipathService = type
        return mutableSelf
    }

    /// Allow fast open to be used on a connection.
    ///
    /// Use fast open for an outbound connection, which may be done at any protocol level.
    /// Use of fast open requires that the caller send idempotent data on the connection
    /// before the connection may move into the ready state.
    ///
    /// > Warning: This may have security implications for application data.
    /// In particular, TLS early data is replayable by a network attacker.
    /// You must account for this when sending data before the handshake
    /// is confirmed. See RFC 8446 for more information. Don't
    /// enable fast open without a specific application profile that defines its use.
    ///
    /// As a side effect, this may implicitly enable fast open or early data for protocols
    /// in the stack, even if they didn't have fast open explicitly enabled on them
    /// (such as the option to enable TCP Fast Open).
    ///
    /// - Parameter allowed: `true` if fast open should be used, otherwise `false`.
    public func fastOpenAllowed(_ allowed: Bool) -> Self {
        var mutableSelf = self
        mutableSelf.parameters.fastOpenEnabled = allowed
        return mutableSelf
    }

    /// Allow or prohibit the use of expired DNS answers during connection establishment.
    ///
    /// If allowed, a DNS answer that was previously returned may be reused for new
    /// connections even after the answers are considered expired. A query for fresh answers
    /// is sent in parallel, and the fresh answers are used as alternate addresses
    /// in case the expired answers don't result in successful connections.
    ///
    /// By default, this value is `.systemDefault`, which allows the system to determine
    /// if it is appropriate to use expired answers.
    ///
    /// - Parameter behavior: The expired DNS behavior to use.
    public func expiredDNSBehavior(_ behavior: Parameters.ExpiredDNSBehavior) -> Self {
        var mutableSelf = self
        mutableSelf.parameters.expiredDNSBehavior = behavior
        return mutableSelf
    }

    public func serverMode(_ val: Bool) -> Self {
        var mutableSelf = self
        mutableSelf.parameters.isServer = val
        return mutableSelf
    }

    public func protocolListenerAttached(_ val: Bool) -> Self {
        var mutableSelf = self
        mutableSelf.parameters.attachProtocolListener = val
        return mutableSelf
    }

    public func parallelConnectionAttemptsProhibited(_ val: Bool) -> Self {
        var mutableSelf = self
        mutableSelf.parameters.parallelConnectionAttemptsProhibited = val
        return mutableSelf
    }
}

/// An extension that adds chainable configuration to parameters.
///
/// Conforms `Parameters` to `ParametersProvider`.
@_spi(Essentials)
@available(Network 0.1.0, *)
extension Parameters: ParametersProvider {
    public var parameters: Parameters {
        get {
            self
        }
        set {
            self = newValue
        }
    }
}

/// Sends and receives unreliable datagrams over QUIC.
///
/// Implements RFC 9221.
@_spi(Essentials)
@available(Network 0.1.0, *)
public struct QUICDatagram: DatagramProtocol {
    public typealias ContentType = [UInt8]

    public let belowProtocol: Void

    public init() {
    }

    public func configure(parameters: Parameters) {
    }

    static public func makeIncomingMessage(content: [UInt8]?, isComplete: Bool) throws(NetworkError) -> Message<[UInt8]>
    {
        // TODO: Should content be optional here?
        guard let content else {
            throw NetworkError.posix(EINVAL)
        }

        return content
    }
}

/// The system definition of the Transport Layer Security (TLS) protocol.
///
/// Supports sending and receiving encrypted byte streams.
@_spi(Essentials)
@available(Network 0.1.0, *)
public struct TLS: StreamProtocol {
    private var trustedRawPublicKeyCertificates: [[UInt8]]?
    private var rawPrivateKey: [UInt8]?
    private var applicationProtocols: [String]?
    private var earlyDataEnabled: Bool?
    private var ticketsEnabled: Bool?

    var options: ProtocolOptions<TLSProtocol> {
        var options = TLSProtocol.Options()
        if let trustedRawPublicKeyCertificates {
            options.trustedRawPublicKeyCertificates = trustedRawPublicKeyCertificates
        }
        if let rawPrivateKey {
            options.rawPrivateKey = rawPrivateKey
        }
        if let applicationProtocols {
            options.applicationProtocols = applicationProtocols
        }
        return ProtocolOptions(protocolIdentifier: TLSProtocol.identifier, perProtocolOptions: options)
    }

    public enum BelowProtocol {
        case tcp(TCP)
        case noTransport(NoTransport)
    }

    public let belowProtocol: BelowProtocol

    /// Create a TLS protocol to use in a protocol stack.
    public init() {
        belowProtocol = .tcp(TCP())
    }

    /// Create a TLS protocol to use in a protocol stack.
    ///
    /// - Parameter builder: The protocol stack below TLS.
    public init(@ProtocolStackBuilder<TCP> _ builder: () -> (TCP)) {
        belowProtocol = .tcp(builder())
    }

    /// Create a TLS protocol to use in a protocol stack.
    ///
    /// - Parameter builder: The protocol stack below TLS.
    public init(@ProtocolStackBuilder<NoTransport> _ builder: () -> (NoTransport)) {
        belowProtocol = .noTransport(builder())
    }

    public func configure(parameters: Parameters) {
        switch belowProtocol {
        case .tcp(let tcp):
            tcp.configure(parameters: parameters)
        case .noTransport(let noTransport):
            noTransport.configure(parameters: parameters)
            break
        }
        let defaultProtocolStack = parameters.defaultStack
        defaultProtocolStack.application.append(.swiftTLS(self.options))
    }

    /// Set the certificates TLS uses during the handshake.
    ///
    /// - Parameter certs: The certs to be used during the TLS handshake.
    public func trustedRawPublicKeyCertificates(_ certs: [[UInt8]]) -> Self {
        var mutableSelf = self
        mutableSelf.trustedRawPublicKeyCertificates = certs
        return mutableSelf
    }

    /// Set the private key TLS uses.
    ///
    /// - Parameter key: The private key to be used.
    public func rawPrivateKey(_ key: [UInt8]) -> Self {
        var mutableSelf = self
        mutableSelf.rawPrivateKey = key
        return mutableSelf
    }

    /// Set application protocols supported by clients of this protocol.
    ///
    /// Application layer protocol negotiation (ALPN) tokens
    /// describe the application protocol in use above TLS.
    ///
    /// - Parameter protocols: An array of application layer protocol
    /// tokens to use for negotiation during the TLS handshake.
    public func applicationProtocols(_ protocols: [String]) -> Self {
        var mutableSelf = self
        mutableSelf.applicationProtocols = protocols
        return mutableSelf
    }
}

/// The system definition of the Transmission Control Protocol (TCP).
///
/// Supports sending and receiving byte streams.
@_spi(Essentials)
@available(Network 0.1.0, *)
public struct TCP: StreamProtocol {
    private var noDelay: Bool?
    private var noPush: Bool?
    private var noOptions: Bool?
    private var keepaliveEnabled: Bool?
    private var keepaliveIdleTime: UInt32?
    private var keepaliveInterval: UInt32?
    private var keepaliveCount: UInt32?
    private var maximumSegmentSize: UInt32?
    private var connectionTimeout: UInt32?
    private var persistTimeout: UInt32?
    private var retransmitConnectionDropTime: UInt32?
    private var retransmitFinDrop: Bool?
    private var disableAckStretching: Bool?
    private var disableECN: Bool?
    private var fastOpen: Bool?
    var options: ProtocolOptions<TCPProtocol> {
        var options = TCPProtocol.Options()
        if let noDelay { options.noDelay = noDelay }
        if let noPush { options.noPush = noPush }
        if let noOptions { options.noOptions = noOptions }
        if let keepaliveEnabled { options.enableKeepalive = keepaliveEnabled }
        if let keepaliveIdleTime { options.keepaliveIdleTime = keepaliveIdleTime }
        if let keepaliveInterval { options.keepaliveInterval = keepaliveInterval }
        if let keepaliveCount { options.keepaliveCount = keepaliveCount }
        if let maximumSegmentSize { options.maximumSegmentSize = maximumSegmentSize }
        if let connectionTimeout { options.connectionTimeout = connectionTimeout }
        if let persistTimeout { options.persistTimeout = persistTimeout }
        if let retransmitConnectionDropTime { options.retransmitConnectionDropTime = retransmitConnectionDropTime }
        if let retransmitFinDrop { options.retransmitFinDrop = retransmitFinDrop }
        if let disableAckStretching { options.disableAckStretching = disableAckStretching }
        if let disableECN { options.disableECN = disableECN }
        if let fastOpen { options.enableFastOpen = fastOpen }
        return ProtocolOptions<TCPProtocol>(protocolIdentifier: TCPProtocol.identifier, perProtocolOptions: options)
    }

    public let belowProtocol: IP

    /// Create an instance of TCP.
    public init() {
        self.belowProtocol = IP()
    }

    /// Create an instance of TCP.
    ///
    /// - Parameter builder: The protocol stack below TCP. Defaults to `IP()`.
    public init(@ProtocolStackBuilder<IP> _ builder: () -> (IP)) {
        belowProtocol = builder()
    }

    /// Disable Nagle's algorithm.
    ///
    /// A boolean indicating that TCP should disable
    /// Nagle's algorithm (`TCP_NODELAY`).
    ///
    /// - Parameter noDelay: `true` to disable Nagle's algorithm, otherwise `false`.
    public func noDelay(_ noDelay: Bool) -> Self {
        var mutableSelf = self
        mutableSelf.noDelay = noDelay
        return mutableSelf
    }

    /// Enable no-push mode.
    ///
    /// A boolean indicating that TCP should use no-push mode (`TCP_NOPUSH`).
    ///
    /// - Parameter noPush: `true` to use no-push mode, otherwise `false`.
    public func noPush(_ noPush: Bool) -> Self {
        var mutableSelf = self
        mutableSelf.noPush = noPush
        return mutableSelf
    }

    /// Enable no-options mode.
    ///
    /// A boolean indicating that TCP should use no-options mode (`TCP_NOOPT`).
    ///
    /// - Parameter noOptions: `true` to use no-options mode, otherwise `false`.
    public func noOptions(_ noOptions: Bool) -> Self {
        var mutableSelf = self
        mutableSelf.noOptions = noOptions
        return mutableSelf
    }

    public func enableKeepalive(_ val: Bool) -> Self {
        var mutableSelf = self
        mutableSelf.keepaliveEnabled = val
        return mutableSelf
    }

    /// Enable TCP keepalives.
    ///
    /// - Parameter idleTimeInSeconds: The number of seconds of idleness to wait before keepalive
    ///		  probes are sent by TCP (`TCP_KEEPALIVE`).
    /// - Parameter count: The number of keepalive probes to send before terminating.
    /// - Parameter intervalInSeconds: The number of seconds of to wait before resending TCP
    ///		   keepalive probes (`TCP_KEEPINTVL`).
    public func keepalive(idleTimeInSeconds: UInt32, count: UInt32, intervalInSeconds: UInt32) -> Self {
        var mutableSelf = self
        mutableSelf.keepaliveEnabled = true
        mutableSelf.keepaliveIdleTime = idleTimeInSeconds
        mutableSelf.keepaliveInterval = intervalInSeconds
        mutableSelf.keepaliveCount = count
        return mutableSelf
    }

    /// Enable TCP keepalives.
    ///
    /// - Parameter idleTime: The number of seconds of idleness to wait before keepalive
    ///		  probes are sent by TCP (`TCP_KEEPALIVE`).
    /// - Parameter count: The number of keepalive probes to send before terminating.
    /// - Parameter interval: The number of seconds of to wait before resending TCP
    ///		   keepalive probes (`TCP_KEEPINTVL`).
    public func keepalive(idleTime: UInt32, count: UInt32, interval: UInt32) -> Self {
        var mutableSelf = self
        mutableSelf.keepaliveEnabled = true
        mutableSelf.keepaliveIdleTime = idleTime
        mutableSelf.keepaliveInterval = interval
        mutableSelf.keepaliveCount = count
        return mutableSelf
    }

    public func keepaliveCount(_ val: UInt32) -> Self {
        var mutableSelf = self
        mutableSelf.keepaliveCount = val
        return mutableSelf
    }

    public func keepaliveIdle(_ val: UInt32) -> Self {
        var mutableSelf = self
        mutableSelf.keepaliveIdleTime = val
        return mutableSelf
    }

    public func keepaliveInterval(_ val: UInt32) -> Self {
        var mutableSelf = self
        mutableSelf.keepaliveInterval = val
        return mutableSelf
    }

    /// Set the maximum segment size.
    ///
    /// The maximum segment size in bytes (`TCP_MAXSEG`).
    ///
    /// - Parameter bytes: The maximum segment size in bytes.
    public func maximumSegmentSize(_ bytes: UInt32) -> Self {
        var mutableSelf = self
        mutableSelf.maximumSegmentSize = bytes
        return mutableSelf
    }

    /// Set the timeout for TCP connection establishment.
    ///
    /// A timeout for TCP connection establishment, in seconds.
    /// (`TCP_CONNECTIONTIMEOUT`).
    ///
    /// - Parameter timeout: The connection establishment timeout, in seconds.
    public func connectionTimeout(_ timeout: UInt32) -> Self {
        var mutableSelf = self
        mutableSelf.connectionTimeout = timeout
        return mutableSelf
    }

    /// Set the TCP persist timeout.
    ///
    /// The TCP persist timeout, in seconds (`PERSIST_TIMEOUT`).
    /// See RFC 6429.
    ///
    /// - Parameter timeout: The persist timeout, in seconds.
    public func persistTimeout(_ timeout: UInt32) -> Self {
        var mutableSelf = self
        mutableSelf.persistTimeout = timeout
        return mutableSelf
    }

    /// Set the TCP retransmission attempt timeout.
    ///
    /// A timeout for TCP retransmission attempts, in seconds
    /// (`TCP_RXT_CONNDROPTIME`).
    ///
    /// - Parameter timeout: The retransmission attempt timeout, in seconds.
    public func retransmitConnectionDropTime(_ timeout: UInt32) -> Self {
        var mutableSelf = self
        mutableSelf.retransmitConnectionDropTime = timeout
        return mutableSelf
    }

    /// Configure TCP to drop the connection after a FIN does not receive an ACK.
    ///
    /// A boolean to cause TCP to drop its connection after
    /// not receiving an ACK after a FIN (`TCP_RXT_FINDROP`).
    ///
    /// - Parameter drop: `true` to drop, otherwise `false`.
    public func retransmitFinDrop(_ drop: Bool) -> Self {
        var mutableSelf = self
        mutableSelf.retransmitFinDrop = drop
        return mutableSelf
    }

    /// Disable ACK stretching.
    ///
    /// A boolean to cause TCP to disable ACK stretching (`TCP_SENDMOREACKS`).
    ///
    /// - Parameter disableAckStretching: `true` to disable ACK stretching, otherwise `false`.
    public func ackStretchingDisabled(_ disableAckStretching: Bool) -> Self {
        var mutableSelf = self
        mutableSelf.disableAckStretching = disableAckStretching
        return mutableSelf
    }

    /// Disable ECN negotiation.
    ///
    /// - Parameter disableECN: `true` to disable ECN, otherwise `false`.
    public func ecnDisabled(_ disableECN: Bool) -> Self {
        var mutableSelf = self
        mutableSelf.disableECN = disableECN
        return mutableSelf
    }

    public func enableFastOpen(_ val: Bool) -> Self {
        var mutableSelf = self
        mutableSelf.fastOpen = val
        return mutableSelf
    }

    /// Configure TCP to enable TCP Fast Open (TFO).
    ///
    /// This may take effect even when TCP is not the top-level protocol
    /// in the protocol stack. For example, if TLS is running over TCP,
    /// the Client Hello message may be sent as fast open data.
    ///
    /// If TCP is the top-level protocol in the stack (the one the app
    /// directly interacts with), TFO is disabled unless the app
    /// indicates that it provides its own fast open data by calling
    /// `Parameters.allowFastOpen`.
    ///
    /// - Parameter allowed: `true` to allow TFO, otherwise `false`.
    public func fastOpenAllowed(_ allowed: Bool) -> Self {
        var mutableSelf = self
        mutableSelf.fastOpen = allowed
        return mutableSelf
    }

    /// Configure TCP to enable TCP Fast Open (TFO).
    ///
    /// This may take effect even when TCP is not the top-level protocol
    /// in the protocol stack. For example, if TLS is running over TCP,
    /// the Client Hello message may be sent as fast open data.
    ///
    /// If TCP is the top-level protocol in the stack (the one the app
    /// directly interacts with), TFO is disabled unless the app
    /// indicates that it provides its own fast open data by calling
    /// `Parameters.allowFastOpen`.
    ///
    /// - Parameter enabled: `true` to enable TFO, otherwise `false`.
    public func fastOpen(_ enabled: Bool) -> Self {
        var mutableSelf = self
        mutableSelf.fastOpen = enabled
        return mutableSelf
    }

    public func configure(parameters: Parameters) {
        belowProtocol.configure(parameters: parameters)
        let defaultProtocolStack = parameters.defaultStack
        defaultProtocolStack.transport = .tcp(options)
    }
}

#if !NETWORK_EMBEDDED
@_spi(Essentials)
@available(Network 0.1.0, *)
public struct DatagramBridge: DatagramProtocol {
    public typealias ContentType = Void

    public let belowProtocol: Void

    init() {
    }

    public func configure(parameters: Parameters) {
        let options = ProtocolOptions<BridgeDatagramProtocol>(
            protocolIdentifier: BridgeDatagramProtocol.identifier,
            perProtocolOptions: BridgeDatagramProtocol.Options()
        )
        parameters.defaultStack.link = .custom(options)
    }
}
#endif

#if !NETWORK_EMBEDDED
@_spi(Essentials)
@available(Network 0.1.0, *)
public struct StreamBridge: StreamProtocol {
    public typealias ContentType = Void

    public let belowProtocol: Void

    init() {
    }

    public func configure(parameters: Parameters) {
        let options = ProtocolOptions<BridgeStreamProtocol>(
            protocolIdentifier: BridgeStreamProtocol.identifier,
            perProtocolOptions: BridgeStreamProtocol.Options()
        )
        parameters.defaultStack.link = .custom(options)
    }
}
#endif

@_spi(Essentials)
@available(Network 0.1.0, *)
public struct NoTransport: StreamProtocol {
    public enum BelowProtocol {
        case void
        #if !NETWORK_EMBEDDED
        case bridge(StreamBridge)
        #endif
    }

    public let belowProtocol: BelowProtocol

    public init() {
        belowProtocol = .void
    }

    #if !NETWORK_EMBEDDED
    public init(@ProtocolStackBuilder<StreamBridge> _ builder: () -> (StreamBridge)) {
        belowProtocol = .bridge(builder())
    }
    #endif

    public func configure(parameters: Parameters) {
        switch belowProtocol {
        #if !NETWORK_EMBEDDED
        case .bridge(let bridge):
            bridge.configure(parameters: parameters)
        #endif
        case .void:
            break
        }
    }
}

/// The system definition of the QUIC protocol.
///
/// Conforms to `MultiplexProtocol`,
/// exposing configuration for a multiplexing instance of QUIC, which
/// in turn exposes the ability to handle multiple streams of data over QUIC.
@_spi(Essentials)
@available(Network 0.1.0, *)
public struct QUIC: MultiplexProtocol {
    private var alpn: [String]
    private var trustedRawPublicKeyCertificates: [[UInt8]]?
    private var rawPrivateKey: [UInt8]?
    private var idleTimeout: Int?
    private var maxUDPPayloadSize: Int?
    private var initialMaxData: Int?
    private var initialMaxStreamDataBidirectionalRemote: Int?
    private var initialMaxStreamDataBidirectionalLocal: Int?
    private var initialMaxStreamDataUnidirectional: Int?
    private var initialMaxBidirectionalStreams: Int?
    private var initialMaxUnidirectionalStreams: Int?
    private var maxDatagramFrameSize: Int?
    private var sourceConnectionIDLength: Int?
    private var peerAuthenticationOptional: Bool?
    private var peerAuthenticationRequired: Bool?
    private var earlyDataEnabled: Bool?
    private var ticketsEnabled: Bool?
    private var serverName: String?

    var options: ProtocolOptions<QUICProtocol> {
        let options = QUICProtocol.Options()
        let connectionOptions = QUICConnectionProtocol.Options()
        var tlsOptions = TLSProtocol.Options()
        tlsOptions.applicationProtocols = self.alpn
        if let trustedRawPublicKeyCertificates {
            tlsOptions.trustedRawPublicKeyCertificates = trustedRawPublicKeyCertificates
        }
        if let rawPrivateKey { tlsOptions.rawPrivateKey = rawPrivateKey }
        if let idleTimeout { connectionOptions.idleTimeout = .milliseconds(idleTimeout) }
        if let maxUDPPayloadSize { connectionOptions.maxUDPPayloadSize = UInt16(maxUDPPayloadSize) }
        if let initialMaxData { connectionOptions.initialMaxData = UInt64(initialMaxData) }
        if let initialMaxStreamDataBidirectionalRemote {
            connectionOptions.initialMaxStreamDataBidirectionalRemote = UInt64(initialMaxStreamDataBidirectionalRemote)
        }
        if let initialMaxStreamDataBidirectionalLocal {
            connectionOptions.initialMaxStreamDataBidirectionalLocal = UInt64(initialMaxStreamDataBidirectionalLocal)
        }
        if let initialMaxStreamDataUnidirectional {
            connectionOptions.initialMaxStreamDataUnidirectional = UInt64(initialMaxStreamDataUnidirectional)
        }
        if let initialMaxBidirectionalStreams {
            connectionOptions.initialMaxStreamsBidirectional = UInt64(initialMaxBidirectionalStreams)
        }
        if let initialMaxUnidirectionalStreams {
            connectionOptions.initialMaxStreamsUnidirectional = UInt64(initialMaxUnidirectionalStreams)
        }
        if let maxDatagramFrameSize { connectionOptions.maxDatagramFrameSize = UInt16(maxDatagramFrameSize) }
        if let sourceConnectionIDLength { connectionOptions.sourceConnectionIDLength = sourceConnectionIDLength }
        connectionOptions.tlsOptions = ProtocolOptions(
            protocolIdentifier: TLSProtocol.identifier,
            perProtocolOptions: tlsOptions
        )
        options.quicConnectionOptions = connectionOptions
        return ProtocolOptions(protocolIdentifier: QUICProtocol.identifier, perProtocolOptions: options)
    }

    public let belowProtocol: UDP

    /// Create a QUIC protocol for use in a protocol stack.
    ///
    /// The application layer protocol negotiation (ALPN) tokens
    /// describe the application protocol in use above QUIC.
    ///
    /// - Parameter alpn: An array of application layer protocol
    /// tokens to use for negotiation during the QUIC handshake.
    public init(alpn: [String]) {
        self.alpn = alpn
        self.belowProtocol = UDP()
    }

    public init(alpn: [String], @ProtocolStackBuilder<UDP> _ builder: () -> (UDP)) {
        self.alpn = alpn
        self.belowProtocol = builder()
    }

    public struct ProtocolStorage: ConnectionStorage {
        public init() {}
    }

    public func configure(parameters: Parameters) {
        belowProtocol.configure(parameters: parameters)
        let defaultProtocolStack = parameters.defaultStack
        defaultProtocolStack.transport = .quic(self.options)
    }

    /// Set the idle timeout for the QUIC connection, in milliseconds.
    ///
    /// If no packets are sent or received within this timeout,
    /// the QUIC connection is closed.
    ///
    /// - Parameter timeout: The idle timeout, in milliseconds.
    public func idleTimeout(_ timeout: Int) -> Self {
        var mutableSelf = self
        mutableSelf.idleTimeout = timeout
        return mutableSelf
    }

    /// Set the maximum length of a QUIC packet
    /// that you are willing to receive on a connection, in bytes.
    ///
    /// - Parameter size: The maximum length, in bytes.
    public func maxUDPPayloadSize(_ size: Int) -> Self {
        var mutableSelf = self
        mutableSelf.maxUDPPayloadSize = size
        return mutableSelf
    }

    /// Set the initial_max_data transport parameter on a QUIC connection.
    ///
    /// - Parameter initialMaxData: The value to use for the `initial_max_data`
    /// transport parameter on a QUIC connection.
    public func initialMaxData(_ initialMaxData: Int) -> Self {
        var mutableSelf = self
        mutableSelf.initialMaxData = initialMaxData
        return mutableSelf
    }

    /// Set the initial_max_stream_data_bidi_remote transport
    /// parameter on a QUIC connection.
    ///
    /// - Parameter initialMaxStreamDataBidiRemote: The value to use for the
    /// `initial_max_stream_data_bidi_remote` transport parameter on a QUIC
    /// connection.
    public func initialMaxStreamDataBidirectionalRemote(_ initialMaxStreamDataBidiRemote: Int) -> Self {
        var mutableSelf = self
        mutableSelf.initialMaxStreamDataBidirectionalRemote = initialMaxStreamDataBidiRemote
        return mutableSelf
    }

    /// Set the initial_max_stream_data_bidi_local transport
    /// parameter on a QUIC connection.
    ///
    /// - Parameter initialMaxStreamDataBidiLocal: The value to use for the
    /// `initial_max_stream_data_bidi_local` transport parameter on a QUIC
    /// connection.
    public func initialMaxStreamDataBidirectionalLocal(_ initialMaxStreamDataBidiLocal: Int) -> Self {
        var mutableSelf = self
        mutableSelf.initialMaxStreamDataBidirectionalLocal = initialMaxStreamDataBidiLocal
        return mutableSelf
    }

    /// Set the initial_max_stream_data_uni transport
    /// parameter on a QUIC connection.
    ///
    /// - Parameter initialMaxStreamDataUni: The value to use for the
    /// `initial_max_stream_data_uni` transport parameter on a QUIC
    /// connection.
    public func initialMaxStreamDataUnidirectional(_ initialMaxStreamDataUni: Int) -> Self {
        var mutableSelf = self
        mutableSelf.initialMaxStreamDataUnidirectional = initialMaxStreamDataUni
        return mutableSelf
    }

    /// Set the initial_max_streams_bidi transport
    /// parameter on a QUIC connection.
    ///
    /// - Parameter initialMaxStreamsBidi: The value to use for the
    /// `initial_max_streams_bidi` transport parameter on a QUIC
    /// connection.
    public func initialMaxBidirectionalStreams(_ initialMaxStreamsBidi: Int) -> Self {
        var mutableSelf = self
        mutableSelf.initialMaxBidirectionalStreams = initialMaxStreamsBidi
        return mutableSelf
    }

    /// Set the initial_max_stream_data_uni transport parameter on a QUIC connection.
    ///
    /// - Parameter initialMaxStreamDataUni: The value to use for the
    /// `initial_max_stream_data_uni` transport parameter on a QUIC
    /// connection.
    public func initialMaxUnidirectionalStreams(_ initialMaxStreamDataUni: Int) -> Self {
        var mutableSelf = self
        mutableSelf.initialMaxUnidirectionalStreams = initialMaxStreamDataUni
        return mutableSelf
    }

    /// Set the initial_max_streams_bidi transport parameter on a QUIC connection.
    ///
    /// - Parameter initialMaxStreamsBidi: The value to use for the
    /// `initial_max_streams_bidi` transport parameter on a QUIC
    /// connection.
    public func maxBidirectionalStreams(_ initialMaxStreamsBidi: Int) -> Self {
        var mutableSelf = self
        mutableSelf.initialMaxBidirectionalStreams = initialMaxStreamsBidi
        return mutableSelf
    }

    /// Set the initial_max_streams_uni transport parameter on a QUIC connection.
    ///
    /// - Parameter initialMaxStreamsUni: The value to use for the
    /// `initial_max_streams_uni` transport parameter on a QUIC
    /// connection.
    public func maxUnidirectionalStreams(_ initialMaxStreamsUni: Int) -> Self {
        var mutableSelf = self
        mutableSelf.initialMaxUnidirectionalStreams = initialMaxStreamsUni
        return mutableSelf
    }

    /// Set the max_datagram_frame_size transport parameter on a QUIC connection.
    ///
    /// - Parameter size: The value to use for the `max_datagram_frame_size`
    /// transport parameter on a QUIC connection.
    public func maxDatagramFrameSize(_ size: Int) -> Self {
        var mutableSelf = self
        mutableSelf.maxDatagramFrameSize = size
        return mutableSelf
    }

    /// Set the length of Connection IDs generated by a QUIC connection.
    ///
    /// - Parameter length: The source Connection ID length to use.
    public func sourceConnectionIDLength(_ length: Int) -> Self {
        var mutableSelf = self
        mutableSelf.sourceConnectionIDLength = length
        return mutableSelf
    }

    /// The TLS configuration to use within QUIC.
    public var tls: TLS {
        QUIC.TLS(self)
    }

    /// The set of TLS options available when using QUIC.
    ///
    /// Used to configure the TLS handshake that runs within the QUIC handshake.
    public struct TLS {
        private var quic: QUIC

        internal init(_ nw: QUIC) {
            self.quic = nw
        }

        /// Set the certificates TLS validates during the handshake.
        ///
        /// - Parameter certs: The peer keys to be validated during the TLS handshake.
        public func trustedRawPublicKeyCertificates(_ certs: [[UInt8]]) -> QUIC {
            var mutableQUIC = self.quic
            mutableQUIC.trustedRawPublicKeyCertificates = certs
            return mutableQUIC
        }

        /// Set the private key TLS uses.
        ///
        /// - Parameter key: The private key to be used.
        public func rawPrivateKey(_ key: [UInt8]) -> QUIC {
            var mutableQUIC = self.quic
            mutableQUIC.rawPrivateKey = key
            return mutableQUIC
        }

        // Early data won't work nicely with these APIs yet
        public func earlyDataEnabled(_ val: Bool) -> QUIC {
            var mutableQUIC = self.quic
            mutableQUIC.earlyDataEnabled = val
            return mutableQUIC
        }

        public func ticketsEnabled(_ val: Bool) -> QUIC {
            var mutableQUIC = self.quic
            mutableQUIC.ticketsEnabled = val
            return mutableQUIC
        }

        /// Set the server name for TLS SNI (Server Name Indication).
        ///
        /// - Parameter name: The server name to use during the TLS handshake.
        public func serverName(_ name: String) -> QUIC {
            var mutableQUIC = self.quic
            mutableQUIC.serverName = name
            return mutableQUIC
        }
    }
}

/// A QUIC stream that runs over a QUIC connection.
///
/// Connections using `QUICStream` have a similar stream interface to TLS and TCP.
///
/// > Note: This type isn't intended to be inserted into the protocol stack manually; it's provided by connections that use QUIC.
@_spi(Essentials)
@available(Network 0.1.0, *)
public struct QUICStream: StreamProtocol {
    public let belowProtocol: Void

    public enum Directionality: Equatable {
        case unidirectional
        case bidirectional
    }

    public enum Initiator: Equatable {
        case client
        case server
    }

    public func configure(parameters: Parameters) {
    }
}

/// The system definition of the User Datagram Protocol (UDP).
///
/// UDP supports sending and receiving datagrams.
@_spi(Essentials)
@available(Network 0.1.0, *)
public struct UDP: DatagramProtocol {
    public typealias ContentType = [UInt8]

    private var preferNoChecksum: Bool?
    var options: ProtocolOptions<UDPProtocol> {
        var options = UDPProtocol.Options()
        if preferNoChecksum != nil { options.insert(.preferNoChecksum) }
        return ProtocolOptions<UDPProtocol>(protocolIdentifier: UDPProtocol.identifier, perProtocolOptions: options)
    }

    public let belowProtocol: IP

    public init() {
        self.belowProtocol = IP()
    }

    public init(@ProtocolStackBuilder<IP> _ builder: () -> (IP)) {
        self.belowProtocol = builder()
    }

    /// Skip computing checksums when sending UDP packets.
    ///
    /// This only takes effect when running over IPv4 (`UDP_NOCKSUM`).
    public func noChecksumPreferred(_ noChecksum: Bool) -> Self {
        var mutableSelf = self
        mutableSelf.preferNoChecksum = noChecksum
        return mutableSelf
    }

    public func configure(parameters: Parameters) {
        belowProtocol.configure(parameters: parameters)
        let defaultProtocolStack = parameters.defaultStack
        defaultProtocolStack.transport = .udp(self.options)
    }
}

/// The system definition of the Internet Protocol (IP).
///
/// Can be used to insert IP into a protocol stack.
///
/// > Note: Specifying IP is optional, and you only need to include it in a
/// protocol stack when configuring IP options.
@_spi(Essentials)
@available(Network 0.1.0, *)
public struct IP: NetworkProtocolOptions {
    public enum BelowProtocol {
        case void
        #if !NETWORK_EMBEDDED
        case bridge(DatagramBridge)
        #endif
    }
    public let belowProtocol: BelowProtocol
    private var version: IPProtocol.Version?
    private var hopLimit: UInt8?
    private var useMinimumMTU: Bool?
    private var disableFragmentation: Bool?
    private var calculateReceiveTime: Bool?
    private var localAddressPreference: IPProtocol.AddressPreference?

    private var disableMulticastLoopback: Bool?
    var options: ProtocolOptions<IPProtocol> {
        var options = IPProtocol.Options()
        if let version { options.version = version }
        if let hopLimit { options.hopLimit = hopLimit }
        if useMinimumMTU != nil {
            var flags = options.flags
            flags.insert(.useMinimumMTU)
            options.flags = flags
        }
        if disableFragmentation != nil {
            var flags = options.flags
            flags.remove(.fragmentationEnabled)
            options.flags = flags
        }
        if calculateReceiveTime != nil {
            var flags = options.flags
            flags.remove(.calculateReceiveTime)
            options.flags = flags
        }
        if let localAddressPreference { options.localAddressPreference = localAddressPreference }
        if disableMulticastLoopback != nil {
            var flags = options.flags
            flags.insert(.disableMulticastLoopback)
            options.flags = flags
        }
        return ProtocolOptions<IPProtocol>(protocolIdentifier: IPProtocol.identifier, perProtocolOptions: options)
    }

    public init() {
        belowProtocol = .void
    }

    #if !NETWORK_EMBEDDED
    public init(@ProtocolStackBuilder<DatagramBridge> _ builder: () -> (DatagramBridge)) {
        belowProtocol = .bridge(builder())
    }
    #endif

    /// Specify a single version of the Internet Protocol to allow.
    ///
    /// Setting this value constrains which address endpoints can
    /// be used and filters DNS results during connection establishment.
    ///
    /// - Parameter version: The IP version, IPv4 or IPv6.
    public func version(_ version: IPProtocol.Version) -> Self {
        var mutableSelf = self
        mutableSelf.version = version
        return mutableSelf
    }

    /// Configure the IP hop limit.
    ///
    /// Equivalent to `IP_TTL` for IPv4
    /// and `IPV6_HOPLIMIT` for IPv6.
    ///
    /// - Parameter limit: The hop limit.
    public func hopLimit(_ limit: UInt8) -> Self {
        var mutableSelf = self
        mutableSelf.hopLimit = limit
        return mutableSelf
    }

    /// Configure IP to use the minimum MTU value.
    ///
    /// The minimum MTU value is 1280 bytes for IPv6 (`IPV6_USE_MIN_MTU`).
    /// This value has no effect for IPv4.
    ///
    /// - Parameter useMinimumMTU: `true` to use the minimum MTU value, otherwise `false`.
    public func minimumMTU(_ useMinimumMTU: Bool) -> Self {
        var mutableSelf = self
        mutableSelf.useMinimumMTU = useMinimumMTU
        return mutableSelf
    }

    /// Configure IP to disable fragmentation on outgoing packets.
    ///
    /// Equivalent to `IP_DONTFRAG` for IPv4 and `IPV6_DONTFRAG` for IPv6.
    ///
    /// - Parameter dontFragment: `true` to disable fragmentation, otherwise `false`.
    public func fragmentationDisabled(_ dontFragment: Bool) -> Self {
        var mutableSelf = self
        mutableSelf.disableFragmentation = dontFragment
        return mutableSelf
    }

    /// Configure IP to calculate receive time for inbound packets.
    ///
    /// - Parameter calculateReceiveTime: `true` to calculate receive time, otherwise `false`.
    public func receiveTimeCalculated(_ calculateReceiveTime: Bool) -> Self {
        var mutableSelf = self
        mutableSelf.calculateReceiveTime = calculateReceiveTime
        return mutableSelf
    }

    /// Specify a preference selecting the local addresses to use with outbound
    /// connections.
    ///
    /// - Parameter preference: The local address preference to use.
    public func localAddressPreference(_ preference: IPProtocol.AddressPreference) -> Self {
        var mutableSelf = self
        mutableSelf.localAddressPreference = preference
        return mutableSelf
    }

    /// Specify if multicast packets should be looped back for local delivery.
    ///
    /// By default, a multicast packet sent to a group to which the sending host itself belongs
    /// is looped back for local delivery. `disableMulticastLoopback` disables
    /// this behavior and, if set, multicast packets aren't looped back to the sender.
    ///
    /// > Note: Only applies to multicast packets.
    ///
    /// - Parameter disableMulticastLoopback: `true` to disable multicast loopback, otherwise `false`.
    public func multicastLoopbackDisabled(_ disableMulticastLoopback: Bool) -> Self {
        var mutableSelf = self
        mutableSelf.disableMulticastLoopback = disableMulticastLoopback
        return mutableSelf
    }

    public func configure(parameters: Parameters) {
        switch belowProtocol {
        #if !NETWORK_EMBEDDED
        case .bridge(let bridge):
            bridge.configure(parameters: parameters)
        #endif
        case .void:
            break
        }
        let defaultProtocolStack = parameters.defaultStack
        defaultProtocolStack.internet = .ip(self.options)
    }
}

@_spi(Essentials)
@available(Network 0.1.0, *)
extension DatagramProtocol {
}

/// A builder that creates and configures parameters from a parameterized protocol stack.
///
/// `ParametersBuilder` is an opaque type that produces a `Parameters` value
/// based on the protocol stack you supply.
@_spi(Essentials)
@available(Network 0.1.0, *)
public struct ParametersBuilder<Top: NetworkProtocolOptions>: ParametersProvider {
    public var parameters: Parameters

    internal let top: Top

    public static func parameters(@ProtocolStackBuilder<Top> _ builder: () -> (Top)) -> ParametersBuilder<Top> {
        ParametersBuilder(builder)
    }

    // TODO: Private?
    public static func parameters(
        initialParameters: Parameters,
        @ProtocolStackBuilder<Top> _ builder: () -> (Top)
    ) -> ParametersBuilder<Top> {
        ParametersBuilder(initialParameters: initialParameters, builder)
    }

    public init(auto: () -> (Top)) {
        self.parameters = Parameters()
        self.top = auto()
        self.top.configure(parameters: self.parameters)
    }

    public init(@ProtocolStackBuilder<Top> _ builder: () -> (Top)) {
        self.parameters = Parameters()
        self.top = builder()
        self.top.configure(parameters: self.parameters)
    }

    internal init(initialParameters: Parameters, @ProtocolStackBuilder<Top> _ builder: () -> (Top)) {
        self.parameters = initialParameters
        self.top = builder()
        self.top.configure(parameters: self.parameters)
    }
}

/// A connection to an endpoint on the network for sending and receiving data.
///
/// A connection handles establishment of any transport, security, and application-level protocols
/// required to transmit and receive user data. A connection may make multiple establishment
/// attempts before the connection is ready.
@_spi(Essentials)
@available(Network 0.1.0, *)
public final class NetworkConnection<ApplicationProtocol: NetworkProtocolOptions>: NetworkChannel<ApplicationProtocol>,
    @unchecked Sendable
{
    // WARNING: DO NOT ADD ANY VARIABLES WITHOUT CHECKING THAT WE REMAIN SENDABLE.
    // ALL mutable state should be guarded and safe from data-races
    fileprivate struct LockedState {
        var stateUpdateHandler: (@Sendable (_ connection: NetworkConnection, _ state: State) -> Void)? = nil
        var firstStream: Bool = true
    }

    fileprivate let lockedState = NetworkMutex<LockedState>(LockedState())

    /// Creates an outbound connection.
    internal override init(kind: Kind, endpoint: Endpoint, parameters: Parameters, uuid: SystemUUID) {
        super.init(kind: kind, endpoint: endpoint, parameters: parameters, uuid: uuid)
    }

    /// Creates an inbound connection.
    internal override init(kind: Kind, using flow: EndpointFlow, uuid: SystemUUID) {
        super.init(kind: kind, using: flow, uuid: uuid)
    }

    public var localEndpoint: Endpoint? {
        get {
            self.endpointFlow.localEndpoint
        }
    }

    /// The remote endpoint of the connection.
    public var remoteEndpoint: Endpoint? {
        get {
            self.endpointFlow.remoteEndpoint
        }
    }

    /// A non-graceful variant of cancel that doesn't allow the transport to close cleanly.
    ///
    /// Performs the same effect as `cancel()`, but skips graceful shutdown of the transport.
    public func forceCancel() {
        cancel()
    }

    // Implement how state changes should be handled for a subclass here
    internal override func onStateChange(_ state: State) {
        if let handler = lockedState.withLock({ lockedState in
            lockedState.stateUpdateHandler
        }) {
            handler(self, state)
        }
    }

    /// Set a closure to be called when the connection's state changes, which may be called
    /// multiple times until the connection is canceled.
    @discardableResult public func onStateUpdate(
        _ handler: (@escaping @Sendable (_ connection: NetworkConnection, _ state: State) -> Void)
    ) -> Self {
        lockedState.withLock { lockedState in
            lockedState.stateUpdateHandler = handler
        }
        return self
    }
}

@_spi(Essentials)
@available(Network 0.1.0, *)
public class NetworkChannelBase {
    public enum State: Equatable, Sendable {
        /// The initial state prior to start.
        case setup
        /// Waiting connections haven't yet been started, or don't have a viable network.
        case waiting(NetworkError)
        /// Preparing connections are actively establishing the connection.
        case preparing
        /// Ready connections can send and receive data.
        case ready
        /// Failed connections are disconnected and can no longer send or receive data.
        case failed(NetworkError)
        /// Canceled connections have been invalidated by the client and send no more events.
        case cancelled

        internal init(_ nw: EndpointFlow.State) {
            switch nw {
            case .setup:
                self = .setup
            case .waiting(let error):
                self = .waiting(error)
            case .preparing:
                self = .preparing
            case .ready:
                self = .ready
            case .failed(let error):
                self = .failed(error)
            case .cancelled:
                self = .cancelled
            }
        }

        public static func == (lhs: State, rhs: State) -> Bool {
            switch (lhs, rhs) {
            case (.setup, .setup):
                return true
            case (.waiting, .waiting):
                return true
            case (.preparing, .preparing):
                return true
            case (.ready, .ready):
                return true
            case (.failed, .failed):
                return true
            case (.cancelled, .cancelled):
                return true
            default:
                return false
            }
        }
    }

    enum Kind {
        case quic
        case udp
        case tcp
        case noTransport
        case tls
    }

    let endpointFlow: EndpointFlow
    var state: State {
        get {
            State(endpointFlow.state)
        }
    }
    let kind: Kind

    init(endpointFlow: EndpointFlow, kind: Kind) {
        self.endpointFlow = endpointFlow
        self.kind = kind
        self.endpointFlow.stateUpdateHandler = { state in
            self.onStateChange(State(state))
        }
    }

    deinit {
        self.endpointFlow.stateUpdateHandler = nil
    }

    internal func onStateChange(_ state: State) {
        // This space left intentionally blank
    }
}

/// A base class supporting sending and receiving data through an arbitrary network channel.
///
/// The interface exposed by this type (and any derived classes) is dependent on the
/// generic `ApplicationProtocol` parameter.
@_spi(Essentials)
@available(Network 0.1.0, *)
public class NetworkChannel<ApplicationProtocol: NetworkProtocolOptions>: NetworkChannelBase,
    CustomDebugStringConvertible, @unchecked Sendable
{
    let uuid: SystemUUID

    /// Compares two channels for equality.
    ///
    /// Compares two instances of `NetworkChannel` for equality.
    public static func == (lhs: NetworkChannel, rhs: NetworkChannel) -> Bool {
        lhs.id == rhs.id
    }

    internal init(kind: Kind, endpoint: Endpoint, parameters: Parameters, uuid: SystemUUID) {
        self.uuid = uuid
        super.init(endpointFlow: EndpointFlow(endpoint: endpoint, parameters: parameters, uuid: uuid), kind: kind)
    }

    internal init(kind: Kind, using flow: EndpointFlow, uuid: SystemUUID) {
        self.uuid = uuid
        super.init(endpointFlow: flow, kind: kind)
    }

    internal init(kind: Kind, joining flow: EndpointFlow, uuid: SystemUUID) {
        self.uuid = uuid
        super.init(endpointFlow: EndpointFlow(existing: flow, uuid: uuid), kind: kind)
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    /// The stable identity of the entity associated with this instance.
    public var id: String {
        String(identifier)
    }

    @discardableResult public func start() -> Self {
        endpointFlow.start()
        return self
    }

    /// Generates a string representation of the channel suitable for logging.
    ///
    /// Returns a description of the underlying `NetworkChannel`.
    public var debugDescription: String {
        endpointFlow.debugDescription
    }

    /// The set of parameters with which the channel was created.
    public var parameters: Parameters {
        get {
            endpointFlow.parameters
        }
    }

    public var identifier: UInt64 {
        get {
            endpointFlow.identifier
        }
    }

    /// Cancels the connection and any registered update handlers.
    ///
    /// Cancellation is asynchronous. The last callback is to the `stateUpdateHandler`
    /// with the canceled state. After that final callback, all blocks are released
    /// to break retain cycles.
    ///
    /// Calls to `cancel()` after the first one are ignored.
    public func cancel() {
        endpointFlow.cancel()
    }

    deinit {
        cancel()
    }

    public func invokeApplicationEvent(_ event: ApplicationEvent) {
        let endpointFlow = self.endpointFlow
        endpointFlow.async {
            endpointFlow.invokeApplicationEvent(event)
        }
    }
}

@_spi(Essentials)
@available(Network 0.1.0, *)
extension NetworkChannel: ConnectionProtocol {
    public typealias ApplicationProtocolType = ApplicationProtocol
}

@_spi(Essentials)
@available(Network 0.1.0, *)
extension NetworkChannel: Identifiable, Hashable {
}

@_spi(Essentials)
@available(Network 0.1.0, *)
extension NetworkConnection where ApplicationProtocol: OneToOneProtocol {
    internal convenience init(kind: Kind, to endpoint: Endpoint, using parameters: Parameters, uuid: SystemUUID) {
        self.init(kind: kind, endpoint: endpoint, parameters: parameters, uuid: uuid)
    }

    /// Create a new connection to an endpoint, with protocol stack.
    ///
    /// - Parameter to: The remote endpoint.
    /// - Parameter using: The protocol stack to use for this connection.
    public convenience init(
        to endpoint: Endpoint,
        uuid: SystemUUID = SystemUUID(),
        @ProtocolStackBuilder<TCP> using builder: () -> (TCP)
    ) where ApplicationProtocol == TCP {
        let builder = ParametersBuilder(builder)
        self.init(kind: .tcp, endpoint: endpoint, parameters: builder.parameters, uuid: uuid)
    }

    public convenience init(
        to endpoint: Endpoint,
        uuid: SystemUUID = SystemUUID(),
        @ProtocolStackBuilder<UDP> using builder: () -> (UDP)
    ) where ApplicationProtocol == UDP {
        let builder = ParametersBuilder(builder)
        self.init(kind: .udp, endpoint: endpoint, parameters: builder.parameters, uuid: uuid)
    }

    public convenience init(
        to endpoint: Endpoint,
        uuid: SystemUUID = SystemUUID(),
        @ProtocolStackBuilder<TLS> using builder: () -> (TLS)
    ) where ApplicationProtocol == TLS {
        let builder = ParametersBuilder(builder)
        self.init(kind: .tls, endpoint: endpoint, parameters: builder.parameters, uuid: uuid)
    }

    public convenience init(
        to endpoint: Endpoint,
        uuid: SystemUUID = SystemUUID(),
        @ProtocolStackBuilder<NoTransport> using builder: () -> (NoTransport)
    ) where ApplicationProtocol == NoTransport {
        let builder = ParametersBuilder(builder)
        self.init(kind: .noTransport, endpoint: endpoint, parameters: builder.parameters, uuid: uuid)
    }

    /// Creates a new outbound connection to an endpoint, with parameters.
    ///
    /// The parameters determine the protocols to be used for the connection, and their options.
    ///
    /// - Parameter to: The remote endpoint to which to connect.
    /// - Parameter using: The parameters that define which protocols and path to use.
    public convenience init(
        to endpoint: Endpoint,
        uuid: SystemUUID = SystemUUID(),
        using builder: ParametersBuilder<TCP>
    ) where ApplicationProtocol == TCP {
        self.init(kind: .tcp, endpoint: endpoint, parameters: builder.parameters, uuid: uuid)
    }

    public convenience init(
        to endpoint: Endpoint,
        uuid: SystemUUID = SystemUUID(),
        using builder: ParametersBuilder<UDP>
    ) where ApplicationProtocol == UDP {
        self.init(kind: .udp, endpoint: endpoint, parameters: builder.parameters, uuid: uuid)
    }

    public convenience init(
        to endpoint: Endpoint,
        uuid: SystemUUID = SystemUUID(),
        using builder: ParametersBuilder<TLS>
    ) where ApplicationProtocol == TLS {
        self.init(kind: .tls, endpoint: endpoint, parameters: builder.parameters, uuid: uuid)
    }

    public convenience init(
        to endpoint: Endpoint,
        uuid: SystemUUID = SystemUUID(),
        using builder: ParametersBuilder<NoTransport>
    ) where ApplicationProtocol == NoTransport {
        self.init(kind: .noTransport, endpoint: endpoint, parameters: builder.parameters, uuid: uuid)
    }
}

@_spi(Essentials)
@available(Network 0.1.0, *)
extension NetworkConnection where ApplicationProtocol: MultiplexProtocol {
    internal convenience init(to endpoint: Endpoint, using parameters: Parameters, uuid: SystemUUID) {
        self.init(kind: .quic, endpoint: endpoint, parameters: parameters, uuid: uuid)
    }

    public convenience init(
        to endpoint: Endpoint,
        uuid: SystemUUID = SystemUUID(),
        @ProtocolStackBuilder<QUIC> using builder: () -> (QUIC)
    ) where ApplicationProtocol == QUIC {
        let builder = ParametersBuilder(builder)
        self.init(to: endpoint, using: builder.parameters, uuid: uuid)
    }

    public convenience init(
        to endpoint: Endpoint,
        uuid: SystemUUID = SystemUUID(),
        using builder: ParametersBuilder<QUIC>
    ) where ApplicationProtocol == QUIC {
        self.init(to: endpoint, using: builder.parameters, uuid: uuid)
    }

    /// Starts the connection.
    ///
    /// Initiates the action to open the connection on the network, for example,
    /// by making a handshake or initiating a multiplexing session. Causes the
    /// connection to evaluate its path, perform resolution, and try to become ready
    /// (connected). Establishment is asynchronous; `onStateUpdate` is called when the
    /// state changes. If the connection can't be established, the state transitions to
    /// `waiting` with an associated error describing the reason. If an unrecoverable
    /// error is encountered, the state transitions to `failed` with an associated
    /// error value. If the connection is established, the state transitions to `ready`.
    ///
    /// Call `start()` only once on a connection; subsequent calls are ignored.
    @discardableResult public func start() -> Self {
        endpointFlow.start()
        return self
    }
}

@_spi(Essentials)
@available(Network 0.1.0, *)
extension QUIC {
    public final class Stream<ApplicationProtocol: NetworkProtocolOptions>: NetworkChannel<ApplicationProtocol>,
        @unchecked Sendable
    {
        // WARNING: DO NOT ADD ANY VARIABLES WITHOUT CHECKING THAT WE REMAIN SENDABLE.
        // ALL mutable state should be guarded and safe from data-races
        fileprivate struct LockedState {
            var reconfigured: Bool = false
            var started: Bool = false

            var stateUpdateHandler:
                (@Sendable (_ connection: QUIC.Stream<ApplicationProtocol>, _ state: State) -> Void)?
            var storage: ApplicationProtocol.ProtocolStorage = ApplicationProtocol.ProtocolStorage.init()
        }
        fileprivate let lockedState = NetworkMutex<LockedState>(LockedState())
        public let parent: NetworkConnection<QUIC>

        internal convenience init(
            using flow: EndpointFlow,
            parent: NetworkConnection<QUIC>,
            uuid: SystemUUID = SystemUUID(),
            @ProtocolStackBuilder<ApplicationProtocol> stackBuilder builder: () -> (ApplicationProtocol)
        ) {
            let _ = ParametersBuilder(builder)
            self.init(using: flow, parent: parent, uuid: uuid)
        }

        internal convenience init(
            using flow: EndpointFlow,
            parent: NetworkConnection<QUIC>,
            uuid: SystemUUID = SystemUUID(),
            newBuilder builder: ParametersBuilder<ApplicationProtocol>
        ) {
            self.init(using: flow, parent: parent, uuid: uuid)
        }

        internal init(using flow: EndpointFlow, parent: NetworkConnection<QUIC>, uuid: SystemUUID) {
            self.parent = parent
            super.init(kind: .quic, using: flow, uuid: uuid)
        }

        internal init(joining flow: EndpointFlow, parent: NetworkConnection<QUIC>, uuid: SystemUUID) {
            self.parent = parent
            super.init(kind: .quic, joining: flow, uuid: uuid)
        }

        /// Set a closure to be called when the connection's state changes, which may be called
        /// multiple times until the connection is canceled.
        @discardableResult public func onStateUpdate(
            _ handler: (@escaping @Sendable (_ connection: Stream, _ state: State) -> Void)
        ) -> Self {
            lockedState.withLock { lockedState in
                lockedState.stateUpdateHandler = handler
            }
            return self
        }

        // Implement how state changes should be handled for a subclass here
        internal override func onStateChange(_ state: State) {
            if let handler = lockedState.withLock({ lockedState in
                lockedState.stateUpdateHandler
            }) {
                handler(self, state)
            }
        }
    }
}

@_spi(Essentials)
@available(Network 0.1.0, *)
extension NetworkConnection where ApplicationProtocol == QUIC {
    private enum ConnectionEvent {
        case newConnection(QUIC.Stream<QUICStream>)
    }

    /// Initiates a new data stream over QUIC.
    ///
    /// When invoked with no parameters, the default stream type is bidirectional.
    /// Unidirectional streams can be initiated by setting the optional `directionality`
    /// parameter to `.unidirectional`.
    ///
    /// This call starts the underlying QUIC connection if it has not been started already
    /// and blocks until the QUIC connection is ready.
    ///
    /// While streams can be canceled independently of the underlying connection,
    /// if the parent `NetworkChannel` is canceled or fails, the streams are too.
    public func openStream(
        directionality: QUICStream.Directionality = .bidirectional,
        uuid: SystemUUID = SystemUUID(),
        completion: @escaping (Result<QUIC.Stream<QUICStream>, any Error>) -> Void
    ) {
        if directionality == .bidirectional {
            let firstStream = lockedState.withLock { lockedState in
                let firstStream = lockedState.firstStream
                lockedState.firstStream = false
                return firstStream
            }

            if firstStream {
                let stream = QUIC.Stream<QUICStream>(using: self.endpointFlow, parent: self, uuid: uuid)
                completion(Result.success(stream))
            } else {
                let stream = QUIC.Stream<QUICStream>(joining: self.endpointFlow, parent: self, uuid: uuid)
                completion(Result.success(stream))
            }
        } else {
            let stream = QUIC.Stream<QUICStream>(joining: self.endpointFlow, parent: self, uuid: uuid)
            completion(Result.success(stream))
        }
    }
}

@_spi(Essentials)
@available(Network 0.1.0, *)
extension NetworkChannel where ApplicationProtocol: MessageProtocol {
}

@_spi(Essentials)
@available(Network 0.1.0, *)
extension NetworkChannel where ApplicationProtocol: StreamProtocol {
    public struct StreamMessage {
        public static func message(content: [UInt8]? = nil, isComplete: Bool = false) -> StreamMessage {
            StreamMessage(content: content, isComplete: isComplete)
        }

        public let content: [UInt8]?
        public let isComplete: Bool
    }

    public func send(_ message: StreamMessage, completion: (@Sendable (Result<Void, NetworkError>) -> Void)? = nil) {
        let endpointFlow = self.endpointFlow
        endpointFlow.async {
            let writeRequest = WriteRequest(
                content: message.content,
                isComplete: message.isComplete,
                completion: completion
            )
            endpointFlow.addWriteRequestOnContext(writeRequest)
        }
    }

    internal func send(
        _ buffer: UnsafeMutableRawBufferPointer,
        owner: AnyObject,
        isComplete: Bool = false,
        completion: (@Sendable (Result<Void, NetworkError>) -> Void)? = nil
    ) {
        let endpointFlow = self.endpointFlow
        endpointFlow.async {
            let writeRequest = WriteRequest(
                buffer: buffer,
                owner: owner,
                isComplete: isComplete,
                completion: completion
            )
            endpointFlow.addWriteRequestOnContext(writeRequest)
        }
    }

    public func receive(
        atLeast minBytes: Int,
        atMost maxBytes: Int,
        completion: @escaping @Sendable (Result<StreamMessage, NetworkError>) -> Void
    ) {
        let readRequest = ReadRequest(minimumBytes: minBytes, maximumBytes: maxBytes, maximumFrames: Int.max) {
            (content, isComplete, isFinal, error) in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(.message(content: content, isComplete: isComplete)))
            }
        }
        self.endpointFlow.addReadRequest(readRequest)
    }
}

@_spi(Essentials)
@available(Network 0.1.0, *)
extension NetworkChannel where ApplicationProtocol: DatagramProtocol {
    public struct DatagramMessage {
        public static func message(content: [UInt8]? = nil) -> DatagramMessage {
            DatagramMessage(content: content)
        }

        public let content: [UInt8]?
    }

    public func send(_ message: DatagramMessage, completion: (@Sendable (Result<Void, NetworkError>) -> Void)? = nil) {
        let endpointFlow = self.endpointFlow
        endpointFlow.async {
            let writeRequest = WriteRequest(content: message.content, isComplete: true, completion: completion)
            endpointFlow.addWriteRequestOnContext(writeRequest)
        }
    }

    internal func send(
        _ buffer: UnsafeMutableRawBufferPointer,
        owner: AnyObject,
        isComplete: Bool = false,
        completion: (@Sendable (Result<Void, NetworkError>) -> Void)? = nil
    ) {
        let endpointFlow = self.endpointFlow
        endpointFlow.async {
            let writeRequest = WriteRequest(
                buffer: buffer,
                owner: owner,
                isComplete: isComplete,
                completion: completion
            )
            endpointFlow.addWriteRequestOnContext(writeRequest)
        }
    }

    public func receive(completion: @escaping @Sendable (Result<DatagramMessage, NetworkError>) -> Void) {
        let readRequest = ReadRequest(minimumBytes: 1, maximumBytes: Int.max, maximumFrames: 1) {
            (content, isComplete, isFinal, error) in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(.message(content: content)))
            }
        }
        self.endpointFlow.addReadRequest(readRequest)
    }
}
