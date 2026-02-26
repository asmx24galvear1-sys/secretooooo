-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Servidor: localhost
-- Tiempo de generación: 26-02-2026 a las 20:22:01
-- Versión del servidor: 10.5.8-MariaDB-log
-- Versión de PHP: 8.2.27

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Base de datos: `GeoRacingDB`
--

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `groups`
--

CREATE TABLE `groups` (
  `id` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `name` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `ownerId` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `createdAt` datetime DEFAULT NULL,
  `isActive` tinyint(1) DEFAULT 1,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `group_members`
--

CREATE TABLE `group_members` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `groupId` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `userId` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `displayName` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `photoUrl` mediumtext COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `joinedAt` datetime DEFAULT NULL,
  `joinedVia` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `sessionId` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `role` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT 'member',
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_membership` (`groupId`,`userId`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `share_sessions`
--

CREATE TABLE `share_sessions` (
  `sessionId` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `groupId` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `ownerId` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `ownerName` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `eventDate` datetime DEFAULT NULL,
  `expiresAt` datetime DEFAULT NULL,
  `createdAt` datetime DEFAULT NULL,
  `isActive` tinyint(1) DEFAULT 1,
  PRIMARY KEY (`sessionId`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `beacons`
--

CREATE TABLE `beacons` (
  `id` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `beacon_uid` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `mode` mediumtext COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `status` mediumtext COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `last_seen` mediumtext COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `arrow` mediumtext COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `message` mediumtext COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `color` mediumtext COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `brightness` int(11) DEFAULT NULL,
  `language` mediumtext COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `evacuationExit` mediumtext COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `configured` tinyint(1) DEFAULT NULL,
  `zone` text COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `arrow_direction` text COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `battery_level` int(11) DEFAULT NULL,
  `last_heartbeat` text COLLATE utf8mb4_unicode_ci DEFAULT NULL
) ENGINE=MyISAM DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `beacons`
--

INSERT INTO `beacons` (`id`, `beacon_uid`, `mode`, `status`, `last_seen`, `arrow`, `message`, `color`, `brightness`, `language`, `evacuationExit`, `configured`, `zone`, `arrow_direction`, `battery_level`, `last_heartbeat`) VALUES
('34e2ea5c-a347-4664-ae94-4b0f194b70b2', 'DESKTOP-LLQDL6V', 'NORMAL', NULL, '2026-02-05 16:03:18', 'UP_LEFT', 'Diagonal Izquierda', '#00FFAA', 100, 'ES', '', 1, NULL, 'UP_LEFT', 80, '2026-02-05 16:03:19'),
('DESKTOP-PB5JVQC', 'DESKTOP-PB5JVQC', 'NORMAL', NULL, '2025-12-20 21:06:50', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `beacon_logs`
--

CREATE TABLE `beacon_logs` (
  `id` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `beacon_uid` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `level` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `message` mediumtext COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `timestamp` datetime DEFAULT NULL
) ENGINE=MyISAM DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `beacon_logs`
--

INSERT INTO `beacon_logs` (`id`, `beacon_uid`, `level`, `message`, `timestamp`) VALUES
('8728342c-e0c4-4bc6-9fdc-02126ab67170', 'DESKTOP-0F131O8', 'INFO', 'ViewModel inicializado para baliza: DESKTOP-0F131O8', '2025-12-13 21:03:48'),
('985c3279-16c7-46c1-88d3-e9ed94e8bc4f', 'DESKTOP-0F131O8', 'INFO', 'ApiLogger initialized', '2025-12-13 21:03:49'),
('9826c7d1-bde9-4380-82fc-9b3e303bdb25', 'DESKTOP-0F131O8', 'INFO', 'ViewModel inicializado para baliza: DESKTOP-0F131O8', '2025-12-13 21:06:03'),
('c1df2c74-d9fe-43a5-8a1c-76e7f5f39268', 'DESKTOP-0F131O8', 'INFO', 'ApiLogger initialized', '2025-12-13 21:06:03'),
('a0dc7c10-c417-423e-b99f-9a96542e7c58', 'DESKTOP-0F131O8', 'INFO', 'ViewModel inicializado para baliza: DESKTOP-0F131O8', '2025-12-13 21:47:32'),
('7f582e22-b38d-4473-b948-fc0e8cfc8e3a', 'DESKTOP-0F131O8', 'INFO', 'ApiLogger initialized', '2025-12-13 21:47:32'),
('6f5ae78b-e215-4f20-b8be-2ae718e7a5e9', 'DESKTOP-0F131O8', 'INFO', 'ViewModel inicializado para baliza: DESKTOP-0F131O8', '2025-12-13 22:20:30'),
('00b86337-3d10-4595-aa5f-dfb9cbd3fd39', 'DESKTOP-0F131O8', 'INFO', 'ApiLogger initialized', '2025-12-13 22:20:30'),
('19ad4dc7-7e5c-4482-979d-6947e113a64f', 'DESKTOP-0F131O8', 'INFO', '↻ Sincronizado: CONGESTION', '2025-12-13 22:26:25'),
('e52bca9b-1e0b-42cd-8564-150742ecfd03', 'DESKTOP-0F131O8', 'INFO', '↻ Sincronizado: EMERGENCY', '2025-12-13 22:26:39'),
('3cd21288-2bc2-46e0-9632-92758fbeba3c', 'DESKTOP-0F131O8', 'INFO', '↻ Sincronizado: NORMAL', '2025-12-13 22:26:53'),
('fc429cba-6283-4a72-ba39-46775c67965e', 'DESKTOP-0F131O8', 'INFO', '↻ Sincronizado: MAINTENANCE', '2025-12-13 22:26:58'),
('9a8b7dec-e475-434e-894b-5df895878ddf', 'DESKTOP-0F131O8', 'INFO', '↻ Sincronizado: EVACUATION', '2025-12-13 22:27:08'),
('c2123c92-b965-4499-b18b-b6d2e98520c1', 'DESKTOP-0F131O8', 'INFO', '↻ Sincronizado: UNCONFIGURED', '2025-12-13 22:27:13'),
('7fa2f6b4-4bc4-4ad7-b857-0578f9557704', 'DESKTOP-0F131O8', 'INFO', '↻ Sincronizado: NORMAL', '2025-12-13 22:27:16'),
('4dbd5bef-2a78-4421-ae23-a47f167d876d', 'DESKTOP-0F131O8', 'INFO', '🚨 MODO GLOBAL EVACUACIÓN ACTIVADO', '2025-12-13 22:27:35'),
('f00b80a9-44a3-44b5-b0bd-6b868ddbf798', 'DESKTOP-0F131O8', 'INFO', '↻ Sincronizado: EVACUATION', '2025-12-13 22:27:35'),
('4e4b4df3-fdd7-4417-b742-3fa21941452c', 'DESKTOP-0F131O8', 'INFO', '✓ FIN DE EVACUACIÓN - Retornando a normalidad', '2025-12-13 22:27:43'),
('242cb2c4-45f4-4663-9260-51d4a08571dd', 'DESKTOP-0F131O8', 'INFO', '↻ Sincronizado: EVACUATION', '2025-12-13 22:27:43'),
('9420e3ef-a501-494b-92e0-f30625ae2c93', 'DESKTOP-0F131O8', 'INFO', '↻ Sincronizado: NORMAL', '2025-12-13 22:28:41'),
('64a197ea-0776-4da0-90e2-fd97cb430e98', 'DESKTOP-0F131O8', 'INFO', '↻ Sincronizado: NORMAL', '2025-12-13 22:30:00'),
('a9d5daf1-487e-49ef-ae40-a46c20548470', 'DESKTOP-0F131O8', 'INFO', '↻ Sincronizado: NORMAL', '2025-12-13 22:30:04'),
('359d1607-2095-463c-aa2a-227f6018d83b', 'DESKTOP-0F131O8', 'INFO', 'ViewModel inicializado para baliza: DESKTOP-0F131O8', '2025-12-13 22:30:38'),
('869eaf2c-8735-4b0e-80fb-e6d8f20d3505', 'DESKTOP-0F131O8', 'INFO', '⚠ API no responde en el inicio', '2025-12-13 22:30:38'),
('0d995a8a-cac0-4df0-a9db-4361b5282bf8', 'DESKTOP-0F131O8', 'INFO', 'ApiLogger initialized', '2025-12-13 22:30:38'),
('10cb3849-60e6-47e9-bc34-774d5d4b4bbd', 'DESKTOP-0F131O8', 'INFO', '🚀 Iniciando servicios de fondo (300ms)...', '2025-12-13 22:30:38'),
('5ae00592-35e0-4b73-b2c6-c3b47e4455f3', 'DESKTOP-0F131O8', 'INFO', '↻ Sincronizado: NORMAL', '2025-12-13 22:30:39'),
('3995d31a-2088-4858-aae5-22a62c576d5a', 'DESKTOP-0F131O8', 'INFO', '🚨 MODO GLOBAL EVACUACIÓN ACTIVADO', '2025-12-13 22:30:40'),
('c41a97a5-8265-4bf9-a742-75467e7875a5', 'DESKTOP-0F131O8', 'INFO', '↻ Sincronizado: EVACUATION', '2025-12-13 22:30:40'),
('b8af4602-d1e7-4dbe-a084-d3abfa21227b', 'DESKTOP-0F131O8', 'INFO', '✓ FIN DE EVACUACIÓN GLOBAL - Cambiando a NORMAL', '2025-12-13 22:30:44'),
('86f9a747-9e7e-407f-97df-30daaedff3d0', 'DESKTOP-0F131O8', 'INFO', '↻ Sincronizado: NORMAL', '2025-12-13 22:30:44'),
('6c8a1d0d-821d-4b09-ba2d-24aa62d6808b', 'DESKTOP-0F131O8', 'INFO', '🚨 MODO GLOBAL EVACUACIÓN ACTIVADO', '2025-12-13 22:48:54'),
('a0e7ea72-cda4-46f8-934b-fcbeb9a7f5ad', 'DESKTOP-0F131O8', 'INFO', '↻ Sincronizado: EVACUATION', '2025-12-13 22:48:54'),
('799d2169-1616-44b1-8f0c-4f472e2210ee', 'DESKTOP-0F131O8', 'INFO', '✓ FIN DE EVACUACIÓN GLOBAL - Cambiando a NORMAL', '2025-12-13 22:48:57'),
('9cde6d99-b81d-487a-9484-0a9b3aed2729', 'DESKTOP-0F131O8', 'INFO', '↻ Sincronizado: NORMAL', '2025-12-13 22:48:57'),
('2cf5c5dc-c70f-4c82-9266-4e670dcd08ea', 'DESKTOP-0F131O8', 'INFO', '🚨 MODO GLOBAL EVACUACIÓN ACTIVADO', '2025-12-13 23:06:40'),
('f17994bb-7849-40fb-8a09-6a2cad95e455', 'DESKTOP-0F131O8', 'INFO', '↻ Sincronizado: EVACUATION', '2025-12-13 23:06:40'),
('cc98e7de-a61d-4251-8b0a-f2abddbe10ff', 'DESKTOP-0F131O8', 'INFO', '✓ FIN DE EVACUACIÓN GLOBAL - Cambiando a NORMAL', '2025-12-13 23:07:04'),
('a111321d-e4eb-4da4-b848-ab3250a2acc2', 'DESKTOP-0F131O8', 'INFO', '↻ Sincronizado: NORMAL', '2025-12-13 23:07:04'),
('9d89e287-8482-45f0-9334-198c765eec51', 'DESKTOP-0F131O8', 'INFO', '🚨 MODO GLOBAL EVACUACIÓN ACTIVADO', '2025-12-13 23:10:48'),
('bbb2a74c-e726-4dac-b035-e39c7bf65592', 'DESKTOP-0F131O8', 'INFO', '↻ Sincronizado: EVACUATION', '2025-12-13 23:10:48'),
('1d4b9414-0e14-48e2-aa88-ec20850f0fb7', 'DESKTOP-0F131O8', 'INFO', '✓ FIN DE EVACUACIÓN GLOBAL - Cambiando a NORMAL', '2025-12-13 23:12:14'),
('7d206ab8-abb5-45cc-b6d6-ef0bf9d78eb8', 'DESKTOP-0F131O8', 'INFO', '↻ Sincronizado: NORMAL', '2025-12-13 23:12:14'),
('37483c36-ab11-4819-b670-7522f2c399fe', 'DESKTOP-0F131O8', 'INFO', '🚨 MODO GLOBAL EVACUACIÓN ACTIVADO', '2025-12-13 23:18:32'),
('0d4fe02d-a55b-4523-9498-cafee3ab6b6e', 'DESKTOP-0F131O8', 'INFO', '↻ Sincronizado: EVACUATION', '2025-12-13 23:18:32'),
('3a82fc27-1634-48ac-bd3c-8b73d1da9271', 'DESKTOP-0F131O8', 'INFO', '✓ FIN DE EVACUACIÓN GLOBAL - Cambiando a NORMAL', '2025-12-13 23:18:53'),
('ab7c9894-996c-4d79-b947-bb4071907090', 'DESKTOP-0F131O8', 'INFO', '↻ Sincronizado: NORMAL', '2025-12-13 23:18:53'),
('19253ae2-4fbe-492f-a2be-78089c998aa1', 'DESKTOP-0F131O8', 'INFO', '🚨 MODO GLOBAL EVACUACIÓN ACTIVADO', '2025-12-13 23:23:51'),
('da2b7351-e531-4704-ba12-9e4ed2d298e6', 'DESKTOP-0F131O8', 'INFO', '↻ Sincronizado: EVACUATION', '2025-12-13 23:23:51'),
('41440976-cb0a-4077-8efc-f4be9c37cfd3', 'DESKTOP-0F131O8', 'INFO', '✓ FIN DE EVACUACIÓN GLOBAL - Cambiando a NORMAL', '2025-12-13 23:24:43'),
('689a6712-fc7a-4701-9bbe-95f776daacfe', 'DESKTOP-0F131O8', 'INFO', '↻ Sincronizado: NORMAL', '2025-12-13 23:24:43'),
('c59ec09a-d9a0-459b-8fa6-f1e526df837e', 'DESKTOP-0F131O8', 'INFO', '🚨 MODO GLOBAL EVACUACIÓN ACTIVADO', '2025-12-13 23:24:51'),
('70367cb4-e5b5-4613-847a-08acecc64f9d', 'DESKTOP-0F131O8', 'INFO', '↻ Sincronizado: EVACUATION', '2025-12-13 23:24:51'),
('07c31a85-8de2-4bc7-8b66-082ca0508990', 'DESKTOP-0F131O8', 'INFO', '✓ FIN DE EVACUACIÓN GLOBAL - Cambiando a NORMAL', '2025-12-13 23:26:53'),
('04b09be1-a7f7-40b3-992c-26ffb0404c9c', 'DESKTOP-0F131O8', 'INFO', '↻ Sincronizado: NORMAL', '2025-12-13 23:26:53'),
('97b5f4bc-16fb-4fe3-be7b-df2bf4c4bc52', 'DESKTOP-0F131O8', 'INFO', '🚨 MODO GLOBAL EVACUACIÓN ACTIVADO', '2025-12-13 23:26:56'),
('478eed2b-7c20-4603-a745-2a8ff78d5453', 'DESKTOP-0F131O8', 'INFO', '↻ Sincronizado: EVACUATION', '2025-12-13 23:26:56'),
('d9d0eec6-b5fc-4e25-be66-8df855c9cd89', 'DESKTOP-0F131O8', 'INFO', '✓ FIN DE EVACUACIÓN GLOBAL - Cambiando a NORMAL', '2025-12-13 23:29:28'),
('1a36884f-ad42-4f5f-90db-091d438e8ce5', 'DESKTOP-0F131O8', 'INFO', '↻ Sincronizado: NORMAL', '2025-12-13 23:29:28'),
('4e23cc2e-8282-4df0-ae33-c62f69643722', 'DESKTOP-0F131O8', 'INFO', '🚨 MODO GLOBAL EVACUACIÓN ACTIVADO', '2025-12-13 23:29:39'),
('9772cc5f-7567-4461-a63e-d8c9cd769b8a', 'DESKTOP-0F131O8', 'INFO', '↻ Sincronizado: EVACUATION', '2025-12-13 23:29:39'),
('8ce8ac2d-0d36-428f-87de-d38dff92cc3f', 'DESKTOP-0F131O8', 'INFO', '✓ FIN DE EVACUACIÓN GLOBAL - Cambiando a NORMAL', '2025-12-13 23:29:43'),
('17944e1d-9cdc-4b1d-bd36-6a19f3aa2b75', 'DESKTOP-0F131O8', 'INFO', '↻ Sincronizado: NORMAL', '2025-12-13 23:29:43'),
('8e429d8b-0878-45ef-b800-fa7790ade61a', 'DESKTOP-0F131O8', 'INFO', '🚨 MODO GLOBAL EVACUACIÓN ACTIVADO', '2025-12-13 23:30:44'),
('c6fed67e-4273-45a5-aadd-abfdc67103a9', 'DESKTOP-0F131O8', 'INFO', '↻ Sincronizado: EVACUATION', '2025-12-13 23:30:44'),
('95cfb852-d65a-4780-b49f-9d9c1d76bf1a', 'DESKTOP-0F131O8', 'INFO', '✓ FIN DE EVACUACIÓN GLOBAL - Cambiando a NORMAL', '2025-12-13 23:32:41'),
('c7733125-48fb-4e7b-800a-26225974b9bb', 'DESKTOP-0F131O8', 'INFO', '↻ Sincronizado: NORMAL', '2025-12-13 23:32:41'),
('401300ef-5244-4578-8c89-37de21ec85f8', 'DESKTOP-0F131O8', 'INFO', '↻ Sincronizado: EVACUATION', '2025-12-13 23:32:46'),
('58b7fc08-7c8b-44e9-8e36-5f3a44796ce7', 'DESKTOP-0F131O8', 'INFO', '✓ FIN DE EVACUACIÓN GLOBAL - Cambiando a NORMAL', '2025-12-13 23:34:11'),
('3b9fb528-5b8f-461e-a1fa-90268d00e727', 'DESKTOP-0F131O8', 'INFO', '↻ Sincronizado: NORMAL', '2025-12-13 23:34:11'),
('472a84a5-405d-4137-8bd8-52e493cff890', 'DESKTOP-0F131O8', 'INFO', '↻ Sincronizado: EVACUATION', '2025-12-13 23:34:16'),
('5364cb0e-8bac-4693-9afe-d3b4a3cf6eb8', 'DESKTOP-LLQDL6V', 'INFO', 'ViewModel inicializado para baliza: DESKTOP-LLQDL6V', '2025-12-17 19:44:45'),
('245ff87b-82e5-45b1-a87e-2ad8125a7b98', 'DESKTOP-LLQDL6V', 'INFO', '⚠ API no responde en el inicio', '2025-12-17 19:44:45'),
('1a8b6d39-8755-4625-98d7-2881cf295b37', 'DESKTOP-LLQDL6V', 'INFO', 'ApiLogger initialized', '2025-12-17 19:44:46'),
('e8c5e0c1-d1fb-45f2-baa8-956e9217d565', 'DESKTOP-LLQDL6V', 'INFO', '🚀 Iniciando servicios de fondo (300ms)...', '2025-12-17 19:44:46'),
('439837ef-ffe0-4d53-9545-9d53c9c86852', 'DESKTOP-LLQDL6V', 'INFO', 'ViewModel inicializado para baliza: DESKTOP-LLQDL6V', '2025-12-17 19:45:27'),
('3e6eff38-6054-4e2c-b8fd-536287e2976e', 'DESKTOP-LLQDL6V', 'INFO', '⚠ API no responde en el inicio', '2025-12-17 19:45:27'),
('02b12919-4bb7-427b-9d50-00e160d1aa02', 'DESKTOP-LLQDL6V', 'INFO', 'ApiLogger initialized', '2025-12-17 19:45:27'),
('3cfd15df-5cc7-421c-85e3-900812a73e36', 'DESKTOP-LLQDL6V', 'INFO', '🚀 Iniciando servicios de fondo (300ms)...', '2025-12-17 19:45:27'),
('1a086054-1bbb-4d8f-83ba-4cf5fd079056', 'DESKTOP-LLQDL6V', 'INFO', '↻ Sincronizado: CONGESTION', '2025-12-17 19:46:38'),
('2edbcb6f-524c-4d7a-b77d-03c3a7f05a67', 'DESKTOP-LLQDL6V', 'INFO', '↻ Sincronizado: EVACUATION', '2025-12-17 19:47:14'),
('2cc6b820-410c-4710-801c-e9707353298d', 'DESKTOP-LLQDL6V', 'INFO', 'ViewModel inicializado para baliza: DESKTOP-LLQDL6V', '2025-12-17 19:50:05'),
('53fee811-22de-4153-8fd0-7287533ec048', 'DESKTOP-LLQDL6V', 'INFO', '⚠ API no responde en el inicio', '2025-12-17 19:50:05'),
('bad297f4-b90b-4374-a3c6-5f7cac7dbed9', 'DESKTOP-LLQDL6V', 'INFO', 'ApiLogger initialized', '2025-12-17 19:50:06'),
('730a9997-b10f-46bc-86ee-d526c45bc7de', 'DESKTOP-LLQDL6V', 'INFO', '🚀 Iniciando servicios de fondo (300ms)...', '2025-12-17 19:50:06'),
('35d08bb8-c0ba-4614-8bb9-3c49be34d6fc', 'DESKTOP-LLQDL6V', 'INFO', '↻ Sincronizado: NORMAL', '2025-12-17 19:50:07'),
('16994a04-cd44-4882-9b90-d261ab411456', 'DESKTOP-PB5JVQC', 'INFO', 'ViewModel inicializado para baliza: DESKTOP-PB5JVQC', '2025-12-20 22:06:10'),
('40eec146-c7a2-40e8-8418-64df200eb168', 'DESKTOP-PB5JVQC', 'INFO', '⚠ API no responde en el inicio', '2025-12-20 22:06:11'),
('a4bfe486-bab3-4509-82ca-1cc36d30fb80', 'DESKTOP-PB5JVQC', 'INFO', 'ApiLogger initialized', '2025-12-20 22:06:11'),
('109c1fd0-1df1-4b8d-adce-a8c3035be56e', 'DESKTOP-PB5JVQC', 'INFO', '🚀 Iniciando servicios de fondo (300ms)...', '2025-12-20 22:06:11'),
('99c2bd2b-db66-4779-afbd-b4845c95c9d8', 'DESKTOP-LLQDL6V', 'INFO', 'ViewModel inicializado para baliza: DESKTOP-LLQDL6V', '2026-01-29 16:22:00'),
('dd2ecb5e-1889-4fca-af7c-9611a9376333', 'DESKTOP-LLQDL6V', 'INFO', '⚠ API no responde en el inicio', '2026-01-29 16:22:01'),
('3fb8bfe1-f94d-4ac7-8ebb-8a96f14c00fc', 'DESKTOP-LLQDL6V', 'INFO', 'ApiLogger initialized', '2026-01-29 16:22:02'),
('05d08ecb-f39f-4f9c-81fc-1516bc0ded4f', 'DESKTOP-LLQDL6V', 'INFO', '🚀 Iniciando servicios de fondo (300ms)...', '2026-01-29 16:22:02'),
('f93a3e5c-9dba-47c7-9373-3ff2f756ffdb', 'DESKTOP-LLQDL6V', 'INFO', '↻ Sincronizado: NORMAL', '2026-01-29 16:22:07'),
('457aae6c-526a-4f6e-97e4-a53896cf8335', 'DESKTOP-LLQDL6V', 'INFO', 'ViewModel inicializado para baliza: DESKTOP-LLQDL6V', '2026-01-29 16:53:06'),
('dcdce60e-c4c9-4215-8a10-59fa26bea79d', 'DESKTOP-LLQDL6V', 'INFO', '⚠ API no responde en el inicio', '2026-01-29 16:53:07'),
('61bb2646-a891-48dd-982d-eb98a69fd1e8', 'DESKTOP-LLQDL6V', 'INFO', 'ApiLogger initialized', '2026-01-29 16:53:10'),
('82234d17-c034-4c3b-bb34-7ffcd29b19c2', 'DESKTOP-LLQDL6V', 'INFO', '🚀 Iniciando servicios de fondo (300ms)...', '2026-01-29 16:53:10'),
('593ac3a0-b962-445b-be66-af4e5ec7d8cd', 'DESKTOP-LLQDL6V', 'INFO', '↻ Sincronizado: NORMAL', '2026-01-29 16:53:12'),
('a4945c9a-4fd1-4d46-ab9a-1e603d12a6c4', 'DESKTOP-LLQDL6V', 'INFO', 'ViewModel inicializado para baliza: DESKTOP-LLQDL6V', '2026-01-29 17:06:39'),
('5ff78266-9c23-4db0-ad14-f1bb4401ccb8', 'DESKTOP-LLQDL6V', 'INFO', '⚠ API no responde en el inicio', '2026-01-29 17:06:41'),
('cfbcb22c-bf36-4910-b54f-49bf59939c5c', 'DESKTOP-LLQDL6V', 'INFO', 'ApiLogger initialized', '2026-01-29 17:06:43'),
('0e610184-2cbd-49fc-b769-648f4d8c00b2', 'DESKTOP-LLQDL6V', 'INFO', '🚀 Iniciando servicios de fondo (300ms)...', '2026-01-29 17:06:43'),
('ffb944af-94d6-48ea-9d51-85e0e1e88e57', 'DESKTOP-LLQDL6V', 'INFO', '↻ Sincronizado: NORMAL', '2026-01-29 17:06:45'),
('ba7b2da4-01d2-4f39-b0ef-07614c21bc25', 'DESKTOP-LLQDL6V', 'INFO', 'ViewModel inicializado para baliza: DESKTOP-LLQDL6V', '2026-01-29 17:07:07'),
('5388c87d-8a54-4804-a42e-2a6babc16502', 'DESKTOP-LLQDL6V', 'INFO', '⚠ API no responde en el inicio', '2026-01-29 17:07:07'),
('aad4a030-3b23-49ec-b44d-0bacb768fb97', 'DESKTOP-LLQDL6V', 'INFO', 'ApiLogger initialized', '2026-01-29 17:07:08'),
('4811673d-ce55-4725-8981-44641b1b9413', 'DESKTOP-LLQDL6V', 'INFO', '🚀 Iniciando servicios de fondo (300ms)...', '2026-01-29 17:07:08'),
('c2795111-92f8-4288-b12a-7c3b04e94b11', 'DESKTOP-LLQDL6V', 'INFO', '↻ Sincronizado: NORMAL', '2026-01-29 17:07:11'),
('f3116919-9a92-40cf-b070-9e693bfcbe75', 'DESKTOP-LLQDL6V', 'INFO', '↻ Sincronizado: CONGESTION', '2026-01-29 17:07:25'),
('9118d94b-515d-4fb6-84b3-3b5f90650ba9', 'DESKTOP-LLQDL6V', 'INFO', '↻ Sincronizado: EVACUATION', '2026-01-29 17:07:33'),
('c57092a4-233b-4a79-a701-261ed0e20b5c', 'DESKTOP-LLQDL6V', 'INFO', '↻ Sincronizado: NORMAL', '2026-01-29 17:07:44'),
('2cdee0f4-ef9d-4bf5-8579-1a3bc3163d9a', 'DESKTOP-LLQDL6V', 'INFO', '↻ Sincronizado: NORMAL', '2026-01-29 17:07:48'),
('526c589f-8cdc-4d7b-a6b2-ffe0a6cc11ec', 'DESKTOP-LLQDL6V', 'INFO', '🚨 MODO GLOBAL EVACUACIÓN ACTIVADO', '2026-01-29 17:07:58'),
('2542d870-2606-47ef-918e-856a2df3e233', 'DESKTOP-LLQDL6V', 'INFO', '↻ Sincronizado: EVACUATION', '2026-01-29 17:07:58'),
('e9f078f7-0b52-4f29-a4fe-0d69812d18c3', 'DESKTOP-LLQDL6V', 'INFO', '✓ FIN DE EVACUACIÓN GLOBAL - Cambiando a NORMAL', '2026-01-29 17:08:08'),
('8bcf2186-c189-4859-a233-2b12c51e607f', 'DESKTOP-LLQDL6V', 'INFO', '↻ Sincronizado: NORMAL', '2026-01-29 17:08:08'),
('b4693c94-9251-4b94-94d9-017cf7f626c1', 'DESKTOP-LLQDL6V', 'INFO', '↻ Sincronizado: EVACUATION', '2026-01-29 17:08:13'),
('c7833ca6-c1d7-4307-b92b-3c59b1fa17d4', 'DESKTOP-LLQDL6V', 'INFO', '↻ Sincronizado: EVACUATION', '2026-01-29 17:08:20'),
('f185d631-2292-437d-9342-5c31a608caed', 'DESKTOP-LLQDL6V', 'INFO', '✓ FIN DE EVACUACIÓN GLOBAL - Cambiando a NORMAL', '2026-01-29 17:08:35'),
('f8a8e96b-fa67-4d5b-8b76-1c1628903010', 'DESKTOP-LLQDL6V', 'INFO', '↻ Sincronizado: NORMAL', '2026-01-29 17:08:36'),
('b0fded63-f0e1-4098-9543-9c326077e209', 'DESKTOP-LLQDL6V', 'INFO', '↻ Sincronizado: NORMAL', '2026-01-29 17:08:42'),
('dbb955cc-89b1-453b-bd63-f0de1f3ab742', 'DESKTOP-LLQDL6V', 'INFO', '🚨 MODO GLOBAL EVACUACIÓN ACTIVADO', '2026-01-29 17:08:45'),
('5e05e514-bd66-4bf5-8c59-dca1a1e2557c', 'DESKTOP-LLQDL6V', 'INFO', '↻ Sincronizado: EVACUATION', '2026-01-29 17:08:45'),
('a2d1f899-144d-4489-b4a8-83b48e86507d', 'DESKTOP-LLQDL6V', 'INFO', 'ViewModel inicializado para baliza: DESKTOP-LLQDL6V', '2026-01-29 17:22:47'),
('6555209d-1821-47b7-abdb-e93eba258176', 'DESKTOP-LLQDL6V', 'INFO', '⚠ API no responde en el inicio', '2026-01-29 17:22:48'),
('9fff3905-7eed-4e97-81c8-84fad712ac67', 'DESKTOP-LLQDL6V', 'INFO', 'ApiLogger initialized', '2026-01-29 17:22:48'),
('beebc121-9628-429e-a1a9-e27d4dd786fd', 'DESKTOP-LLQDL6V', 'INFO', '🚀 Iniciando servicios de fondo (300ms)...', '2026-01-29 17:22:48'),
('7eb525c3-e7b1-4173-ae1b-c366c48c1635', 'DESKTOP-LLQDL6V', 'INFO', '↻ Sincronizado: NORMAL', '2026-01-29 17:22:49'),
('18cdb11c-1c3a-4181-8fe9-b08efb18c874', 'DESKTOP-LLQDL6V', 'INFO', '↻ Sincronizado: NORMAL', '2026-01-29 17:23:21'),
('5f7013c7-67bc-4d43-9e27-8fbcc2f6203e', 'DESKTOP-LLQDL6V', 'INFO', '↻ Sincronizado: NORMAL', '2026-01-29 17:23:29'),
('d9ac8c85-2b73-4a27-bd45-0783e1ffc4d4', 'DESKTOP-LLQDL6V', 'INFO', '🚨 MODO GLOBAL EVACUACIÓN ACTIVADO', '2026-01-29 17:23:37'),
('bf97b6a2-366e-472f-89a8-817b6d4cadea', 'DESKTOP-LLQDL6V', 'INFO', '↻ Sincronizado: EVACUATION', '2026-01-29 17:23:37'),
('8ae2f9dd-272c-4101-8d61-23378742b986', 'DESKTOP-LLQDL6V', 'INFO', '↻ Sincronizado: EVACUATION', '2026-01-29 17:23:46'),
('651de276-4ee2-44e5-bff6-8fb34752748b', 'DESKTOP-LLQDL6V', 'INFO', '✓ FIN DE EVACUACIÓN GLOBAL - Cambiando a NORMAL', '2026-01-29 17:23:50'),
('51237624-da9b-49b8-b758-3f0469dc6047', 'DESKTOP-LLQDL6V', 'INFO', '↻ Sincronizado: NORMAL', '2026-01-29 17:23:51'),
('8d325377-b9ca-45d6-a565-6c7578bc2984', 'DESKTOP-LLQDL6V', 'INFO', '↻ Sincronizado: EVACUATION', '2026-01-29 17:23:55'),
('238c8b78-6b29-48c2-a9e3-9242799d2996', 'DESKTOP-LLQDL6V', 'INFO', '↻ Sincronizado: NORMAL', '2026-01-29 17:23:58'),
('94a5fb43-3306-4b13-8c94-e0d03b6b95d2', 'DESKTOP-LLQDL6V', 'INFO', 'ViewModel inicializado para baliza: DESKTOP-LLQDL6V', '2026-01-29 17:32:05'),
('27adff02-3da4-4433-a20e-9f22cba41e71', 'DESKTOP-LLQDL6V', 'INFO', '⚠ API no responde en el inicio', '2026-01-29 17:32:05'),
('7f522c12-e4b9-4884-823f-aa0b4c2ea1ef', 'DESKTOP-LLQDL6V', 'INFO', 'ApiLogger initialized', '2026-01-29 17:32:06'),
('57560fb8-1dca-4748-a8cc-8b7ee6851258', 'DESKTOP-LLQDL6V', 'INFO', '🚀 Iniciando servicios de fondo (300ms)...', '2026-01-29 17:32:06'),
('961a7637-d443-4883-b331-ca19715f9821', 'DESKTOP-LLQDL6V', 'INFO', '↻ Sincronizado: NORMAL', '2026-01-29 17:32:07'),
('a383a17c-e434-44ce-b792-e640b192fdf2', 'DESKTOP-LLQDL6V', 'INFO', '↻ Sincronizado: NORMAL', '2026-01-29 17:32:17'),
('7b8a50c5-7fc9-4b6a-9f60-cc5d205d669c', 'DESKTOP-LLQDL6V', 'INFO', 'ViewModel inicializado para baliza: DESKTOP-LLQDL6V', '2026-01-29 17:35:39'),
('a4810c2b-49dd-49ae-99de-2942b8eb71ed', 'DESKTOP-LLQDL6V', 'INFO', '⚠ API no responde en el inicio', '2026-01-29 17:35:43'),
('55742d3c-1042-4464-9a98-6ad23014d8c5', 'DESKTOP-LLQDL6V', 'INFO', 'ApiLogger initialized', '2026-01-29 17:35:46'),
('7cb8e7fd-c809-4df1-ade7-da76656008a8', 'DESKTOP-LLQDL6V', 'INFO', '🚀 Iniciando servicios de fondo (300ms)...', '2026-01-29 17:35:46'),
('7ca27bac-99de-4877-a20d-dd5d98cecba7', 'DESKTOP-LLQDL6V', 'INFO', '↻ Sincronizado: NORMAL', '2026-01-29 17:35:47'),
('c217c4bf-f0ed-42ba-8035-c71a511feae7', 'DESKTOP-LLQDL6V', 'INFO', '↻ Sincronizado: NORMAL', '2026-01-29 17:36:04'),
('d94546b8-8579-4dad-8ecf-1a70dbdb38e0', 'DESKTOP-LLQDL6V', 'INFO', 'ViewModel inicializado para baliza: DESKTOP-LLQDL6V', '2026-01-29 17:38:59'),
('8c0ee2ac-ad70-41a0-83cc-8314787301b5', 'DESKTOP-LLQDL6V', 'INFO', '⚠ API no responde en el inicio', '2026-01-29 17:39:00'),
('f4321e08-6ce6-4373-93a2-278f17884010', 'DESKTOP-LLQDL6V', 'INFO', 'ApiLogger initialized', '2026-01-29 17:39:01'),
('7c71f09f-dca0-491e-b468-4c14bf5ef4e7', 'DESKTOP-LLQDL6V', 'INFO', '🚀 Iniciando servicios de fondo (300ms)...', '2026-01-29 17:39:01'),
('065ab4b9-027a-45b6-b0fd-bcc418433408', 'DESKTOP-LLQDL6V', 'INFO', '↻ Sincronizado: NORMAL', '2026-01-29 17:39:02'),
('de583c43-7428-459d-a684-56c9af021fa2', 'DESKTOP-LLQDL6V', 'INFO', '↻ Sincronizado: NORMAL', '2026-01-29 17:39:12'),
('876d8c11-ca05-4add-9c4c-afdb931e8d59', 'DESKTOP-LLQDL6V', 'INFO', '↻ Sincronizado: NORMAL', '2026-01-29 17:39:17'),
('431f9edb-9fc0-468f-9937-67bfc6796547', 'DESKTOP-LLQDL6V', 'INFO', '↻ Sincronizado: NORMAL', '2026-01-29 17:39:22'),
('4d45299a-161d-45be-9f44-e8c7758ad848', 'DESKTOP-LLQDL6V', 'INFO', '↻ Sincronizado: NORMAL', '2026-01-29 17:39:27'),
('11d94c97-8767-4854-a4c5-aafa24156058', 'DESKTOP-LLQDL6V', 'INFO', '↻ Sincronizado: NORMAL', '2026-01-29 17:39:34'),
('29108464-5ea2-44d7-ae1d-23add7456087', 'DESKTOP-LLQDL6V', 'INFO', '↻ Sincronizado: NORMAL', '2026-01-29 17:39:52'),
('e5b7d8c7-2ed1-48b2-b969-ce0c392d77f9', 'DESKTOP-LLQDL6V', 'INFO', '↻ Sincronizado: EMERGENCY', '2026-01-29 17:40:05'),
('e5780ef8-8802-4aec-be65-a99850743b60', 'DESKTOP-LLQDL6V', 'INFO', '↻ Sincronizado: EMERGENCY', '2026-01-29 17:40:13'),
('96c7f3ce-c639-4ce5-a39b-f84a121437ff', 'DESKTOP-LLQDL6V', 'INFO', '↻ Sincronizado: CONGESTION', '2026-01-29 17:40:19'),
('60f45619-8c58-4a6b-aff3-1968ef44ff38', 'DESKTOP-LLQDL6V', 'INFO', '🚨 MODO GLOBAL EVACUACIÓN ACTIVADO', '2026-01-29 17:40:36'),
('5c25be3a-4a0c-4f34-a3c1-1a34c72031b9', 'DESKTOP-LLQDL6V', 'INFO', '↻ Sincronizado: EVACUATION', '2026-01-29 17:40:36'),
('e56245e1-ee2a-4bd9-8bb0-9e1a0c2833f1', 'DESKTOP-LLQDL6V', 'INFO', '✗ Error al enviar heartbeat: An error occurred while sending the request.', '2026-01-29 17:40:52'),
('46a35863-ddf6-42f4-aba1-c30e5fc9eb84', 'DESKTOP-LLQDL6V', 'INFO', '✓ FIN DE EVACUACIÓN GLOBAL - Cambiando a NORMAL', '2026-01-29 17:41:00'),
('91d4d00f-f5fd-46c1-917d-4b75ef6dbca2', 'DESKTOP-LLQDL6V', 'INFO', '↻ Sincronizado: NORMAL', '2026-01-29 17:41:01'),
('b9006604-0c75-4cd5-be0f-56d1ae027747', 'DESKTOP-LLQDL6V', 'INFO', '↻ Sincronizado: NORMAL', '2026-01-29 17:41:18'),
('f58fa6d4-19d9-43f9-8e51-5de1aa6e024c', 'DESKTOP-LLQDL6V', 'INFO', 'ViewModel inicializado para baliza: DESKTOP-LLQDL6V', '2026-01-29 17:43:57'),
('c4ae1304-2ae1-4fd1-beca-fc95d8ee96fb', 'DESKTOP-LLQDL6V', 'INFO', '⚠ API no responde en el inicio', '2026-01-29 17:43:57'),
('5d4009ec-20fd-41be-8f88-99a12f75baa8', 'DESKTOP-LLQDL6V', 'INFO', 'ApiLogger initialized', '2026-01-29 17:43:57'),
('ba92c93d-605f-4550-ba28-702eb2d8d8f3', 'DESKTOP-LLQDL6V', 'INFO', '🚀 Iniciando servicios de fondo (300ms)...', '2026-01-29 17:43:57'),
('3764539d-c9d9-499c-8c26-7aedde088a57', 'DESKTOP-LLQDL6V', 'INFO', '↻ Sincronizado: NORMAL', '2026-01-29 17:43:59'),
('e93aded5-9b2a-44de-9c44-a9aa84f5e1f7', 'DESKTOP-LLQDL6V', 'INFO', 'ViewModel inicializado para baliza: DESKTOP-LLQDL6V', '2026-02-02 15:16:40'),
('35221c70-26c1-4f1a-bee2-d464975a918a', 'DESKTOP-LLQDL6V', 'INFO', 'ApiLogger initialized', '2026-02-02 15:16:55'),
('4a5b5e83-010a-46c1-ab9c-f291728ee007', 'DESKTOP-LLQDL6V', 'INFO', '⚠ API no responde en el inicio', '2026-02-02 15:16:44'),
('8ca8168f-b3f3-45a0-932c-a533114a155a', 'DESKTOP-LLQDL6V', 'INFO', '🚀 Iniciando servicios de fondo (300ms)...', '2026-02-02 15:16:55'),
('0c5d4ba6-faa7-454a-b371-74ea895834b4', 'DESKTOP-LLQDL6V', 'INFO', '↻ Sincronizado: NORMAL', '2026-02-02 15:17:03'),
('b013de80-9b15-4ae9-97a0-b12b31abe35d', 'DESKTOP-LLQDL6V', 'INFO', '↻ Sincronizado: CONGESTION', '2026-02-02 15:17:27'),
('20bf179f-2e47-44d1-9ef9-883b89f13913', 'DESKTOP-LLQDL6V', 'INFO', 'ViewModel inicializado para baliza: DESKTOP-LLQDL6V', '2026-02-02 15:21:26'),
('ab5c688a-1c89-48b6-8a6b-6f6e50d5d631', 'DESKTOP-LLQDL6V', 'INFO', '⚠ API no responde en el inicio', '2026-02-02 15:21:27'),
('2d279b04-1277-448c-b287-82159671851f', 'DESKTOP-LLQDL6V', 'INFO', 'ApiLogger initialized', '2026-02-02 15:21:27'),
('6e2e4257-b7bb-4d1e-8b3f-c52e9b0376a6', 'DESKTOP-LLQDL6V', 'INFO', '🚀 Iniciando servicios de fondo (300ms)...', '2026-02-02 15:21:27'),
('71f0cbbf-d356-4934-adc7-e25da74a4921', 'DESKTOP-LLQDL6V', 'INFO', '↻ Sincronizado: NORMAL', '2026-02-02 15:21:33'),
('a85d03f9-f2df-4cbf-9ba6-43c9b5af3b41', 'DESKTOP-LLQDL6V', 'INFO', '↻ Sincronizado: NORMAL', '2026-02-02 15:21:37'),
('df1b4451-8ebb-4cf4-a8e2-509f7e30dfd7', 'DESKTOP-LLQDL6V', 'INFO', 'ViewModel inicializado para baliza: DESKTOP-LLQDL6V', '2026-02-02 16:03:46'),
('c32a4437-95b1-4ecd-8feb-f547507b35e7', 'DESKTOP-LLQDL6V', 'INFO', '⚠ API no responde en el inicio', '2026-02-02 16:03:46'),
('1c4e6867-e7ca-40e3-a35f-9ef8c888f5d9', 'DESKTOP-LLQDL6V', 'INFO', 'ApiLogger initialized', '2026-02-02 16:03:46'),
('fa4fd838-aa1b-4209-a644-b019ab522ed5', 'DESKTOP-LLQDL6V', 'INFO', '🚀 Iniciando servicios de fondo (300ms)...', '2026-02-02 16:03:46'),
('0090ce01-36d6-48d4-a37a-f6e147a8bc85', 'DESKTOP-LLQDL6V', 'INFO', '↻ Sincronizado: NORMAL', '2026-02-02 16:03:50'),
('5d29edb8-ea97-4e0a-8bd2-088cde156299', 'DESKTOP-LLQDL6V', 'INFO', '↻ Sincronizado: CONGESTION', '2026-02-02 16:04:06'),
('f1a8918a-9ec3-492f-9ffe-95154fca46e6', 'DESKTOP-LLQDL6V', 'INFO', '↻ Sincronizado: EMERGENCY', '2026-02-02 16:04:17'),
('61ae12e7-74e3-49c9-a90e-0e0bc7329ea4', 'DESKTOP-LLQDL6V', 'INFO', '↻ Sincronizado: MAINTENANCE', '2026-02-02 16:04:27'),
('13791b17-3c39-48b4-9331-ebbc814cdff9', 'DESKTOP-LLQDL6V', 'INFO', '↻ Sincronizado: EVACUATION', '2026-02-02 16:04:28'),
('3bbd13b9-6258-45f9-814a-c056e2cfd5e3', 'DESKTOP-LLQDL6V', 'INFO', '↻ Sincronizado: MAINTENANCE', '2026-02-02 16:04:34'),
('f8291756-7410-433f-810c-ac0e5ef73cf1', 'DESKTOP-LLQDL6V', 'INFO', 'ViewModel inicializado para baliza: DESKTOP-LLQDL6V', '2026-02-02 16:09:39'),
('ee2e8b0d-c2c9-46b4-87d2-e2e3fe354573', 'DESKTOP-LLQDL6V', 'INFO', '⚠ API no responde en el inicio', '2026-02-02 16:09:41'),
('1d8abf08-389a-4efb-9a5c-fdcc0cf27184', 'DESKTOP-LLQDL6V', 'INFO', 'ApiLogger initialized', '2026-02-02 16:09:44'),
('3bd57791-5608-4e18-93f6-b03effd6deb4', 'DESKTOP-LLQDL6V', 'INFO', '🚀 Iniciando servicios de fondo (300ms)...', '2026-02-02 16:09:44'),
('df7b749d-0aa7-4d74-ac04-ad26c4993a58', 'DESKTOP-LLQDL6V', 'INFO', '↻ Sincronizado: NORMAL', '2026-02-02 16:09:45'),
('568aee10-8f77-4e53-9a51-8dab5c90405f', 'DESKTOP-LLQDL6V', 'INFO', '↻ Sincronizado: CONGESTION', '2026-02-02 16:09:51'),
('c4ad03e9-b285-455e-9b85-70389d7ecbdf', 'DESKTOP-LLQDL6V', 'INFO', '↻ Sincronizado: EMERGENCY', '2026-02-02 16:09:55'),
('fa69d83a-90cd-4bc8-8334-7232ab0d60aa', 'DESKTOP-LLQDL6V', 'INFO', '↻ Sincronizado: CONGESTION', '2026-02-02 16:09:55'),
('c368df91-d574-4dcd-91a3-30077c650b1b', 'DESKTOP-LLQDL6V', 'INFO', '↻ Sincronizado: EMERGENCY', '2026-02-02 16:09:59'),
('79808068-fddf-40c0-8368-7e179fb6f53e', 'DESKTOP-LLQDL6V', 'INFO', '↻ Sincronizado: EVACUATION', '2026-02-02 16:10:06'),
('724640a0-84c2-44f6-9700-f0c34d9b89a2', 'DESKTOP-LLQDL6V', 'INFO', '↻ Sincronizado: MAINTENANCE', '2026-02-02 16:10:10'),
('dc54eed0-7b5e-42f1-99db-b73b2b97f833', 'DESKTOP-LLQDL6V', 'INFO', '↻ Sincronizado: NORMAL', '2026-02-02 16:10:22'),
('25c30087-353c-4472-8dca-99997dce5cc6', 'DESKTOP-LLQDL6V', 'INFO', 'ViewModel inicializado para baliza: DESKTOP-LLQDL6V', '2026-02-02 16:45:40'),
('92c6d4e7-f228-4d33-8ed6-486c6e91ac2d', 'DESKTOP-LLQDL6V', 'INFO', '⚠ API no responde en el inicio', '2026-02-02 16:45:41'),
('d029d00b-4b4b-4682-98aa-12b356741521', 'DESKTOP-LLQDL6V', 'INFO', 'ApiLogger initialized', '2026-02-02 16:45:44'),
('4e86d94f-069b-448e-8629-bb7d6db00d59', 'DESKTOP-LLQDL6V', 'INFO', '🚀 Iniciando servicios de fondo (300ms)...', '2026-02-02 16:45:44'),
('e95eab48-4bde-4ead-8cc7-c5aaa1dcd448', 'DESKTOP-LLQDL6V', 'INFO', '↻ Sincronizado: NORMAL', '2026-02-02 16:45:46'),
('7557bc71-a9a9-4515-8173-1c67b14fbb68', 'DESKTOP-LLQDL6V', 'INFO', '⚠ Comando expirado (ignorando): CLOSE_APP (ID: cd4538c6-ea91-4549-a3a7-c7c816b2e808). Age: 5701,5 min', '2026-02-02 16:45:46'),
('2a9da944-556d-4c28-85ef-b15f4f8e2d13', 'DESKTOP-LLQDL6V', 'INFO', '⚠ Comando expirado (ignorando): RESTART (ID: e77b4e86-0296-4b49-85cc-7a7695d34b32). Age: 5700,7 min', '2026-02-02 16:45:46'),
('b383fa88-5a61-4244-b87d-7124814a75b6', 'DESKTOP-LLQDL6V', 'INFO', '⚠ Comando expirado (ignorando): SHUTDOWN (ID: a9dd0dde-2689-4820-a98c-e5d5d0dc4752). Age: 5700,7 min', '2026-02-02 16:45:46'),
('536241c0-b2b4-4833-a6f4-117c63a54b13', 'DESKTOP-LLQDL6V', 'INFO', '⚠ Comando expirado (ignorando): RESTART (ID: e77b4e86-0296-4b49-85cc-7a7695d34b32). Age: 5700,7 min', '2026-02-02 16:45:46'),
('4f3d9fd0-6b49-4b51-b0bd-464407ee2f91', 'DESKTOP-LLQDL6V', 'INFO', '⚠ Comando expirado (ignorando): UPDATE_CONFIG (ID: aab5b3a4-b0ff-49de-ae44-c77c41e6d642). Age: 88,3 min', '2026-02-02 16:45:46'),
('8a1124d2-6a3b-4d67-84db-3ebb2cc82a78', 'DESKTOP-LLQDL6V', 'INFO', '⚠ Comando expirado (ignorando): SHUTDOWN (ID: a9dd0dde-2689-4820-a98c-e5d5d0dc4752). Age: 5700,7 min', '2026-02-02 16:45:46'),
('6374433b-5d19-4443-a070-c093cee078e9', 'DESKTOP-LLQDL6V', 'INFO', '⚠ Comando expirado (ignorando): UPDATE_CONFIG (ID: 98cfd1a6-ed2f-4e1d-8cb0-93f842930890). Age: 84,1 min', '2026-02-02 16:45:46'),
('a97d532f-d562-442c-836c-9d9cae8aae47', 'DESKTOP-LLQDL6V', 'INFO', '⚠ Comando expirado (ignorando): UPDATE_CONFIG (ID: aab5b3a4-b0ff-49de-ae44-c77c41e6d642). Age: 88,3 min', '2026-02-02 16:45:46'),
('1f38dbaa-8b94-4df5-8436-28ba14350173', 'DESKTOP-LLQDL6V', 'INFO', '⚠ Comando expirado (ignorando): UPDATE_CONFIG (ID: 98cfd1a6-ed2f-4e1d-8cb0-93f842930890). Age: 84,1 min', '2026-02-02 16:45:46'),
('fc09eeb1-6de5-40ff-915a-c3c6ad61ac4c', 'DESKTOP-LLQDL6V', 'INFO', '⚠ Comando expirado (ignorando): UPDATE_CONFIG (ID: 98cfd1a6-ed2f-4e1d-8cb0-93f842930890). Age: 84,1 min', '2026-02-02 16:45:46'),
('37460278-5f24-4fe6-a700-ea174dfbb9fa', 'DESKTOP-LLQDL6V', 'INFO', '⚠ Comando expirado (ignorando): UPDATE_CONFIG (ID: c07e1418-7cf1-4b88-9b9a-3c46fc4c6428). Age: 84,0 min', '2026-02-02 16:45:46'),
('4e5ddfa7-2f2c-4de0-b268-14280c153de9', 'DESKTOP-LLQDL6V', 'INFO', '⚠ Comando expirado (ignorando): UPDATE_CONFIG (ID: c07e1418-7cf1-4b88-9b9a-3c46fc4c6428). Age: 84,0 min', '2026-02-02 16:45:46'),
('5fc50992-d547-49db-8c56-e9a9c3bf4daa', 'DESKTOP-LLQDL6V', 'INFO', '⚠ Comando expirado (ignorando): UPDATE_CONFIG (ID: c07e1418-7cf1-4b88-9b9a-3c46fc4c6428). Age: 84,0 min', '2026-02-02 16:45:46'),
('49f65661-bc66-4e10-808d-a1eca407d334', 'DESKTOP-LLQDL6V', 'INFO', '[CMD] Recibido: UPDATE_CONFIG (ID: 01fefdf7-ef51-453c-8b7e-45e573f881bf)', '2026-02-02 16:45:46'),
('078d6e99-8ccc-45a0-9072-c61d41d60afb', 'DESKTOP-LLQDL6V', 'INFO', '✓ Configuración actualizada', '2026-02-02 16:45:46'),
('d72b0488-8411-4cc0-9ccd-686e19d17dd1', 'DESKTOP-LLQDL6V', 'INFO', '↻ Sincronizado: NORMAL', '2026-02-02 16:45:46'),
('6f03cb44-bb65-4ec5-ac8e-1c983320e6ca', 'DESKTOP-LLQDL6V', 'INFO', '[CMD] Recibido: UPDATE_CONFIG (ID: 01fefdf7-ef51-453c-8b7e-45e573f881bf)', '2026-02-02 16:45:46'),
('fcf6bd45-cb70-4b8e-ab23-1a7a2ba2f5ad', 'DESKTOP-LLQDL6V', 'INFO', '✓ Configuración actualizada', '2026-02-02 16:45:46'),
('9309bd9d-0b89-4238-bbf1-fd0600d578cb', 'DESKTOP-LLQDL6V', 'INFO', 'ViewModel inicializado para baliza: DESKTOP-LLQDL6V', '2026-02-02 16:47:18'),
('ad426e1c-5880-4c48-9813-7a6c3c8dc7c3', 'DESKTOP-LLQDL6V', 'INFO', '⚠ API no responde en el inicio', '2026-02-02 16:47:20'),
('1e748d7e-708a-4903-8cf0-ee5e46b32a93', 'DESKTOP-LLQDL6V', 'INFO', 'ApiLogger initialized', '2026-02-02 16:47:22'),
('8a84430d-9a04-4784-842c-e6516255996e', 'DESKTOP-LLQDL6V', 'INFO', '🚀 Iniciando servicios de fondo (300ms)...', '2026-02-02 16:47:22'),
('e1699819-cefe-4246-92c4-b8d69e7a07a3', 'DESKTOP-LLQDL6V', 'INFO', '↻ Sincronizado: NORMAL', '2026-02-02 16:47:23'),
('56b76358-6506-41d1-8233-4d82e293bb60', 'DESKTOP-LLQDL6V', 'INFO', 'ViewModel inicializado para baliza: DESKTOP-LLQDL6V', '2026-02-02 16:47:48'),
('9c4be230-e78d-4e68-9940-cd9b55fd4306', 'DESKTOP-LLQDL6V', 'INFO', '⚠ API no responde en el inicio', '2026-02-02 16:47:48'),
('85ff6995-1d1e-430c-9af2-4fb57b112517', 'DESKTOP-LLQDL6V', 'INFO', 'ApiLogger initialized', '2026-02-02 16:47:49'),
('d0df4cd5-009a-4059-bec5-d378e6aa54cd', 'DESKTOP-LLQDL6V', 'INFO', '🚀 Iniciando servicios de fondo (300ms)...', '2026-02-02 16:47:49'),
('42166609-802e-4c15-8961-479a5195edd9', 'DESKTOP-LLQDL6V', 'INFO', '↻ Sincronizado: NORMAL', '2026-02-02 16:47:50'),
('7b2debb8-c9e7-4e5f-991d-81760d6a8832', 'DESKTOP-LLQDL6V', 'INFO', '[CMD] Recibido: RESTART (ID: 33ec00a5-345f-45c1-990b-5abeed62ee48)', '2026-02-02 16:48:02'),
('8aadbb36-93e3-44f6-a4f4-ea20abb7e4ac', 'DESKTOP-LLQDL6V', 'INFO', '🔄 Ejecutando REINICIO DE WINDOWS...', '2026-02-02 16:48:02'),
('9045bad4-3a4b-472b-9ea1-f388c6284ea5', 'DESKTOP-LLQDL6V', 'INFO', 'ViewModel inicializado para baliza: DESKTOP-LLQDL6V', '2026-02-02 17:21:06'),
('8d196b51-9ab5-45f9-97ac-15911079278f', 'DESKTOP-LLQDL6V', 'INFO', '⚠ API no responde en el inicio', '2026-02-02 17:21:06'),
('84d94671-7633-4231-b9bc-e3c919e52df1', 'DESKTOP-LLQDL6V', 'INFO', 'ApiLogger initialized', '2026-02-02 17:21:07'),
('cf9b949a-3abf-4def-b3c3-38d924749d31', 'DESKTOP-LLQDL6V', 'INFO', '🚀 Iniciando servicios de fondo (300ms)...', '2026-02-02 17:21:07'),
('124c0fd2-3e7d-4390-b344-fd262b293034', 'DESKTOP-LLQDL6V', 'INFO', '↻ Sincronizado: NORMAL', '2026-02-02 17:21:08'),
('736d00c4-5631-4410-b96b-87625670dc8c', 'DESKTOP-LLQDL6V', 'INFO', '↻ Sincronizado: NORMAL', '2026-02-02 17:21:24'),
('b7bf1202-7760-4f5d-8952-e1dfa984d9a1', 'DESKTOP-LLQDL6V', 'INFO', '[CMD] Recibido: UPDATE_CONFIG (ID: 926bfa5d-b22d-476f-bb8c-173c018718f1)', '2026-02-02 17:21:24'),
('431fb0b5-c98d-49e0-b7ae-900eed5d4905', 'DESKTOP-LLQDL6V', 'INFO', '✓ Configuración actualizada', '2026-02-02 17:21:24'),
('ea66c417-c987-4f7b-a0fa-9a35b104ad6b', 'DESKTOP-LLQDL6V', 'INFO', '↻ Sincronizado: NORMAL', '2026-02-02 17:21:29'),
('41271760-9a03-4d12-a68c-1f36edbacbf8', 'DESKTOP-LLQDL6V', 'INFO', '[CMD] Recibido: UPDATE_CONFIG (ID: 0bda8757-450d-4a33-a686-addf17b0e951)', '2026-02-02 17:21:29'),
('b42bef99-dc75-4f24-8371-aed2fc253d1c', 'DESKTOP-LLQDL6V', 'INFO', '✓ Configuración actualizada', '2026-02-02 17:21:29'),
('c1ec8bf8-956b-4305-bd8f-19e720b7feb0', 'DESKTOP-LLQDL6V', 'INFO', '[CMD] Recibido: UPDATE_CONFIG (ID: 0bda8757-450d-4a33-a686-addf17b0e951)', '2026-02-02 17:21:30'),
('40b57bea-12d3-4524-b6f4-2eab9a619a32', 'DESKTOP-LLQDL6V', 'INFO', '✓ Configuración actualizada', '2026-02-02 17:21:30'),
('33a2e1ed-de0c-433d-a924-3094f812be6b', 'DESKTOP-LLQDL6V', 'INFO', '[CMD] Recibido: UPDATE_CONFIG (ID: d48a7910-d416-4303-81e6-c8e4edd8dab2)', '2026-02-02 17:21:51'),
('ba66a368-b7b9-41c4-ace9-a11e06f8979c', 'DESKTOP-LLQDL6V', 'INFO', '✓ Configuración actualizada', '2026-02-02 17:21:51'),
('bb3f8996-c6a0-46d8-846b-6387121eb0e7', 'DESKTOP-LLQDL6V', 'INFO', '🚨 MODO GLOBAL EVACUACIÓN ACTIVADO', '2026-02-02 17:22:34'),
('953ceb2c-b490-499c-b6f8-708ed7047e05', 'DESKTOP-LLQDL6V', 'INFO', '↻ Sincronizado: NORMAL', '2026-02-02 17:22:34'),
('df90c24e-19e0-49ce-acab-80ba9a31abd8', 'DESKTOP-LLQDL6V', 'INFO', '🚨 MODO GLOBAL EVACUACIÓN ACTIVADO', '2026-02-02 17:22:34'),
('114eea4c-3227-4676-ae55-931c93685caa', 'DESKTOP-LLQDL6V', 'INFO', '↻ Sincronizado: EVACUATION', '2026-02-02 17:22:34'),
('b1933980-e4ac-4793-94c9-4485c50bc943', 'DESKTOP-LLQDL6V', 'INFO', '✓ FIN DE EVACUACIÓN GLOBAL - Cambiando a NORMAL', '2026-02-02 17:22:51'),
('57279213-e9a4-4371-9d27-b297fb64df3a', 'DESKTOP-LLQDL6V', 'INFO', '↻ Sincronizado: NORMAL', '2026-02-02 17:22:51'),
('2beb4c05-6af8-46da-82a0-c3cf769e5a4e', 'DESKTOP-LLQDL6V', 'INFO', '↻ Sincronizado: EVACUATION', '2026-02-02 17:22:56'),
('8fcefaa8-55e2-4cd5-9aa3-ebd65ff09da4', 'DESKTOP-LLQDL6V', 'INFO', 'ViewModel inicializado para baliza: DESKTOP-LLQDL6V', '2026-02-02 17:39:09'),
('6d140c38-7d7f-4c6d-be0f-01af9c65b443', 'DESKTOP-LLQDL6V', 'INFO', '⚠ API no responde en el inicio', '2026-02-02 17:39:15'),
('52a0af2e-3eea-4323-8201-f8f902fd0bd4', 'DESKTOP-LLQDL6V', 'INFO', 'ApiLogger initialized', '2026-02-02 17:39:23'),
('09c4d455-e6fd-4a1e-b963-a70598e5f6ce', 'DESKTOP-LLQDL6V', 'INFO', '🚀 Iniciando servicios de fondo (300ms)...', '2026-02-02 17:39:23'),
('8c1b7e0a-b47c-4ece-b0de-e278eefcb09d', 'DESKTOP-LLQDL6V', 'INFO', '↻ Sincronizado: NORMAL', '2026-02-02 17:39:24'),
('b44dcb24-3c72-4d1d-a541-38f4edde7d29', 'DESKTOP-LLQDL6V', 'INFO', '🚨 MODO GLOBAL EVACUACIÓN ACTIVADO', '2026-02-02 17:39:28'),
('83dc0f0b-cf8f-4d64-9869-10df95a253ba', 'DESKTOP-LLQDL6V', 'INFO', '↻ Sincronizado: EVACUATION', '2026-02-02 17:39:28'),
('5e58e663-08c9-412b-9d90-3973c646e337', 'DESKTOP-LLQDL6V', 'INFO', '✗ Error al enviar heartbeat: An error occurred while sending the request.', '2026-02-02 17:39:38'),
('10ab81cd-b98e-4faf-bb55-35b752d7d9c8', 'DESKTOP-LLQDL6V', 'INFO', '↻ Sincronizado: NORMAL', '2026-02-02 17:39:49'),
('2119a9a9-dee0-4a0c-9d83-cef95896b0c6', 'DESKTOP-LLQDL6V', 'INFO', '↻ Sincronizado: EVACUATION', '2026-02-02 17:39:54'),
('e4244698-8e72-4e77-891e-b573d35f4eb9', 'DESKTOP-LLQDL6V', 'INFO', '↻ Sincronizado: NORMAL', '2026-02-02 17:39:55'),
('b2f56bab-1ce4-40c7-ace8-485cb08cb6b8', 'DESKTOP-LLQDL6V', 'INFO', '🚨 MODO GLOBAL EVACUACIÓN ACTIVADO', '2026-02-02 17:40:01'),
('147e2654-e5ae-4f05-ab46-6f4fedebdb30', 'DESKTOP-LLQDL6V', 'INFO', '↻ Sincronizado: EVACUATION', '2026-02-02 17:40:01'),
('5faebfdb-2ba5-4c26-936b-cbf704834698', 'DESKTOP-LLQDL6V', 'INFO', '✓ FIN DE EVACUACIÓN GLOBAL - Cambiando a NORMAL', '2026-02-02 17:40:46'),
('115a9302-9e64-4caf-b1ef-e10a362c8a7a', 'DESKTOP-LLQDL6V', 'INFO', '↻ Sincronizado: NORMAL', '2026-02-02 17:40:46'),
('b684af33-a524-4f40-b1d6-524bb024a1fc', 'DESKTOP-LLQDL6V', 'INFO', '↻ Sincronizado: EVACUATION', '2026-02-02 17:40:51'),
('12735c74-2ba3-466c-9828-200509cb9d2c', 'DESKTOP-LLQDL6V', 'INFO', '✗ Error al enviar heartbeat: An error occurred while sending the request.', '2026-02-02 17:42:39'),
('87d1e741-fe91-40ce-85fe-9d8dfad983f1', 'DESKTOP-LLQDL6V', 'INFO', 'ViewModel inicializado para baliza: DESKTOP-LLQDL6V', '2026-02-05 16:41:33'),
('1c9fbe18-416a-47a1-ab62-ef7d2be56446', 'DESKTOP-LLQDL6V', 'INFO', '⚠ API no responde en el inicio', '2026-02-05 16:41:37'),
('a4e52539-226d-4114-b75e-322ef7ff5a18', 'DESKTOP-LLQDL6V', 'INFO', 'ApiLogger initialized', '2026-02-05 16:41:45'),
('4541799b-2a8f-49d9-9341-ccb60319bedc', 'DESKTOP-LLQDL6V', 'INFO', '🚀 Iniciando servicios de fondo (300ms)...', '2026-02-05 16:41:45'),
('05750e5c-2ee3-403b-97a0-7c95d48dd5d8', 'DESKTOP-LLQDL6V', 'INFO', '↻ Sincronizado: NORMAL', '2026-02-05 16:41:49'),
('041c724b-2932-452a-983e-4315d51844f1', 'DESKTOP-LLQDL6V', 'INFO', '🚨 MODO GLOBAL EVACUACIÓN ACTIVADO', '2026-02-05 16:42:25'),
('511c265d-d0ee-4f77-81ed-3f0c4d889313', 'DESKTOP-LLQDL6V', 'INFO', '↻ Sincronizado: EVACUATION', '2026-02-05 16:42:26'),
('ec98e8e5-80e0-4fb2-80f4-da8b3678c919', 'DESKTOP-LLQDL6V', 'INFO', '✓ FIN DE EVACUACIÓN GLOBAL - Cambiando a NORMAL', '2026-02-05 16:42:57'),
('0ec6065f-08d9-4489-9d44-aff9253ce506', 'DESKTOP-LLQDL6V', 'INFO', '↻ Sincronizado: NORMAL', '2026-02-05 16:42:57'),
('4fab1f54-ba7a-4a2f-aff7-77f7cb1c90a4', 'DESKTOP-LLQDL6V', 'INFO', '↻ Sincronizado: EVACUATION', '2026-02-05 16:43:02'),
('e8f15c88-d436-4970-8228-a1d662246613', 'DESKTOP-LLQDL6V', 'INFO', '↻ Sincronizado: NORMAL', '2026-02-05 16:43:14'),
('e002dc29-4f96-442e-9985-56cb469b38fa', 'DESKTOP-LLQDL6V', 'INFO', '[CMD] Recibido: UPDATE_CONFIG (ID: 1293f762-319e-4523-a392-84bf0af94237)', '2026-02-05 16:43:14'),
('7faca867-5e08-4a8b-aa34-1ca4eb97f41b', 'DESKTOP-LLQDL6V', 'INFO', '✓ Configuración actualizada', '2026-02-05 16:43:14'),
('bcb1d3ad-9bf2-442d-a926-b360f944b13e', 'DESKTOP-LLQDL6V', 'INFO', 'ViewModel inicializado para baliza: DESKTOP-LLQDL6V', '2026-02-05 16:43:33'),
('5a1f82b5-061d-46de-b6c6-3e0834d974fe', 'DESKTOP-LLQDL6V', 'INFO', '⚠ API no responde en el inicio', '2026-02-05 16:43:34'),
('7e703b38-7150-413f-9a21-78e242670f65', 'DESKTOP-LLQDL6V', 'INFO', 'ApiLogger initialized', '2026-02-05 16:43:34'),
('44b928ea-18e7-4b0d-9879-dd885d77d93f', 'DESKTOP-LLQDL6V', 'INFO', '🚀 Iniciando servicios de fondo (300ms)...', '2026-02-05 16:43:34'),
('664679fb-92ec-4e70-b289-233a9091aba9', 'DESKTOP-LLQDL6V', 'INFO', '↻ Sincronizado: NORMAL', '2026-02-05 16:43:36'),
('9b858b8e-5451-457f-bfd3-696c3d0af31b', 'DESKTOP-LLQDL6V', 'INFO', 'ViewModel inicializado para baliza: DESKTOP-LLQDL6V', '2026-02-05 16:53:49'),
('7249a2e8-c72e-43f3-a9b1-ce8d7ef34e53', 'DESKTOP-LLQDL6V', 'INFO', '⚠ API no responde en el inicio', '2026-02-05 16:53:49'),
('2317ef22-aa92-4f47-8837-4a4efbba8f66', 'DESKTOP-LLQDL6V', 'INFO', 'ApiLogger initialized', '2026-02-05 16:53:50'),
('a3ddd67b-a0bb-415a-8e7c-2a99d4e33334', 'DESKTOP-LLQDL6V', 'INFO', '🚀 Iniciando servicios de fondo (300ms)...', '2026-02-05 16:53:50'),
('6ad8cb75-eb09-43cc-9205-1ddf64b6cb44', 'DESKTOP-LLQDL6V', 'INFO', '↻ Sincronizado: NORMAL', '2026-02-05 16:53:52'),
('d492e7aa-e17b-45d0-8dbc-a25727cc853f', 'DESKTOP-LLQDL6V', 'INFO', 'ViewModel inicializado para baliza: DESKTOP-LLQDL6V', '2026-02-05 16:58:06'),
('23a14ad3-fed9-4177-8760-5a65e8b3961d', 'DESKTOP-LLQDL6V', 'INFO', '⚠ API no responde en el inicio', '2026-02-05 16:58:06'),
('0a5e61a2-a813-4bf4-b48d-58d0e527033c', 'DESKTOP-LLQDL6V', 'INFO', 'ApiLogger initialized', '2026-02-05 16:58:07'),
('a5e4c69d-a629-468a-b9dc-65771c74038b', 'DESKTOP-LLQDL6V', 'INFO', '🚀 Iniciando servicios de fondo (300ms)...', '2026-02-05 16:58:07'),
('b529f53e-dec1-4511-8b80-4e1bb03a3225', 'DESKTOP-LLQDL6V', 'INFO', '↻ Sincronizado: NORMAL', '2026-02-05 16:58:08'),
('85756e6e-eb78-4d4d-a401-d3d9da832830', 'DESKTOP-LLQDL6V', 'INFO', 'ViewModel inicializado para baliza: DESKTOP-LLQDL6V', '2026-02-05 16:59:19'),
('037b2338-6582-413e-aa36-87e4bbe03584', 'DESKTOP-LLQDL6V', 'INFO', '⚠ API no responde en el inicio', '2026-02-05 16:59:20'),
('f01c4dc1-fd0a-499c-ab9c-33759dee5e6a', 'DESKTOP-LLQDL6V', 'INFO', 'ApiLogger initialized', '2026-02-05 16:59:20'),
('73204924-97fd-4c63-92a4-df7a9c5f49dd', 'DESKTOP-LLQDL6V', 'INFO', '🚀 Iniciando servicios de fondo (300ms)...', '2026-02-05 16:59:20'),
('220abef2-2533-4daf-ae3f-f517eebff70b', 'DESKTOP-LLQDL6V', 'INFO', '↻ Sincronizado: NORMAL', '2026-02-05 16:59:21'),
('d45c1421-ed94-41f7-85e3-7e6e0b97f9a2', 'DESKTOP-LLQDL6V', 'INFO', 'ViewModel inicializado para baliza: DESKTOP-LLQDL6V', '2026-02-05 17:02:09'),
('8c505381-07fe-452f-8cd6-21817b0548c8', 'DESKTOP-LLQDL6V', 'INFO', '⚠ API no responde en el inicio', '2026-02-05 17:02:09'),
('3352a8a8-e2b3-48d6-9a84-bebeb1a338ba', 'DESKTOP-LLQDL6V', 'INFO', 'ApiLogger initialized', '2026-02-05 17:02:09'),
('3c025462-bc5e-4bc3-b957-818d8a61e150', 'DESKTOP-LLQDL6V', 'INFO', '🚀 Iniciando servicios de fondo (300ms)...', '2026-02-05 17:02:09'),
('4309349c-8ecf-43fe-b4e4-8223013296e2', 'DESKTOP-LLQDL6V', 'INFO', '↻ Sincronizado: NORMAL', '2026-02-05 17:02:11'),
('a0a6d63b-d706-400a-8446-688865708881', 'DESKTOP-LLQDL6V', 'INFO', '🚨 MODO GLOBAL EVACUACIÓN ACTIVADO', '2026-02-05 17:02:32'),
('6438082e-c4b9-45d5-aadd-3deb07371cb6', 'DESKTOP-LLQDL6V', 'INFO', '↻ Sincronizado: EVACUATION', '2026-02-05 17:02:32'),
('fa6f48a8-39c0-40ca-ad01-997d817d0997', 'DESKTOP-LLQDL6V', 'INFO', '✓ FIN DE EVACUACIÓN GLOBAL - Cambiando a NORMAL', '2026-02-05 17:02:46'),
('7d37c1e2-614b-4d39-acc2-39d6e72470db', 'DESKTOP-LLQDL6V', 'INFO', '↻ Sincronizado: NORMAL', '2026-02-05 17:02:47');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `circuit_state`
--

CREATE TABLE `circuit_state` (
  `id` varchar(255) NOT NULL,
  `global_mode` varchar(50) DEFAULT NULL,
  `message` text DEFAULT NULL,
  `evacuation_route` text DEFAULT NULL,
  `last_updated` datetime DEFAULT NULL,
  `mode` text DEFAULT NULL,
  `updated_at` text DEFAULT NULL,
  `temperature` varchar(20) DEFAULT NULL,
  `humidity` varchar(50) DEFAULT NULL,
  `wind` varchar(50) DEFAULT NULL,
  `forecast` varchar(100) DEFAULT NULL
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Volcado de datos para la tabla `circuit_state`
--

INSERT INTO `circuit_state` (`id`, `global_mode`, `message`, `evacuation_route`, `last_updated`, `mode`, `updated_at`, `temperature`, `humidity`, `wind`, `forecast`) VALUES
('1', 'NORMAL', '', NULL, '2026-02-26 12:13:58', NULL, NULL, '14.9°C', '70%', '5.5 km/h S', 'Parcialmente nublado');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `commands`
--

CREATE TABLE `commands` (
  `id` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `beacon_uid` mediumtext COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `beacon_id` mediumtext COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `command` mediumtext COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `value` mediumtext COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `status` mediumtext COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `executed` int(11) DEFAULT NULL,
  `created_at` mediumtext COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `executed_at` text COLLATE utf8mb4_unicode_ci DEFAULT NULL
) ENGINE=MyISAM DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `food_stands`
--

CREATE TABLE `food_stands` (
  `id` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `name` text COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `description` text COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `latitude` double DEFAULT NULL,
  `longitude` double DEFAULT NULL,
  `zone` text COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `waitMinutes` int(11) DEFAULT NULL,
  `rating` double DEFAULT NULL,
  `isOpen` int(11) DEFAULT NULL
) ENGINE=MyISAM DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `food_stands`
--

INSERT INTO `food_stands` (`id`, `name`, `description`, `latitude`, `longitude`, `zone`, `waitMinutes`, `rating`, `isOpen`) VALUES
('0da08a76-0754-4f8a-b15b-6c6439dd7039', '🍔 Burger Pit', 'Hamburguesas y patatas', 41.57, 2.261, 'Tribuna Principal', 8, 4.5, 1),
('db079b91-2c26-4103-be42-60d2ce3a142a', '🍔 Burger Pit', 'Hamburguesas y patatas', 41.57, 2.261, 'Tribuna Principal', 8, 4.5, 1),
('2ac8fb2b-c9fe-4c71-89be-13ad2cc3d496', '🍕 Pizza Box', 'Pizzas artesanales al horno', 41.571, 2.262, 'Paddock', 12, 4.2, 1),
('6579c5cd-e2ac-45e3-92e1-8772c66cf5d9', '🍕 Pizza Box', 'Pizzas artesanales al horno', 41.571, 2.262, 'Paddock', 12, 4.2, 1),
('80e1a9b0-2555-4305-a4d2-7cb4402adce1', '🌮 Taco Stand', 'Tacos y burritos mexicanos', 41.569, 2.26, 'Zona Fan', 5, 4.7, 1),
('8abdef89-6458-4e8d-ab46-cffacf0f4ed4', '🌮 Taco Stand', 'Tacos y burritos mexicanos', 41.569, 2.26, 'Zona Fan', 5, 4.7, 1),
('3611d26e-35b4-48dc-ac60-8597a033000d', '🍺 Bar Central', 'Bebidas frías y snacks', 41.57, 2.263, 'Grada Norte', 3, 4, 1),
('534588c5-a711-4531-832b-2f6d7069c6fc', '🍺 Bar Central', 'Bebidas frías y snacks', 41.57, 2.263, 'Grada Norte', 3, 4, 1);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `gamification_profile`
--

CREATE TABLE `gamification_profile` (
  `id` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `totalXP` int(11) DEFAULT NULL,
  `level` int(11) DEFAULT NULL,
  `unlockedAchievements` text COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `circuitsVisited` int(11) DEFAULT NULL,
  `kmWalked` int(11) DEFAULT NULL,
  `friendsInGroup` int(11) DEFAULT NULL
) ENGINE=MyISAM DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `gamification_profile`
--

INSERT INTO `gamification_profile` (`id`, `totalXP`, `level`, `unlockedAchievements`, `circuitsVisited`, `kmWalked`, `friendsInGroup`) VALUES
('current_user', 400, 2, 'exp_first_visit', 0, 0, 0);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `groups`
--

CREATE TABLE `groups` (
  `id` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `name` text COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `owner_id` text COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `members` text COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` int(11) DEFAULT NULL
) ENGINE=MyISAM DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `incidents`
--

CREATE TABLE `incidents` (
  `id` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `category` text COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `description` text COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `timestamp` int(11) DEFAULT NULL,
  `level` text COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `zone` text COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `status` text COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` text COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `type` text COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `title` text COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `priority` text COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `reported_at` int(11) DEFAULT NULL
) ENGINE=MyISAM DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `incidents`
--

INSERT INTO `incidents` (`id`, `category`, `description`, `timestamp`, `level`, `zone`, `status`, `created_at`, `type`, `title`, `priority`, `reported_at`) VALUES
('d56b3cab-6ed3-4d9f-8d37-6e38d41f3af6', 'aaa', 'aaa', NULL, 'INFO', '1', 'ACTIVE', '2026-02-07 14:09:12', NULL, NULL, NULL, NULL),
('inc_1770476247990', NULL, 'Incidente simulado desde Debug Panel', NULL, NULL, 'Tribuna Principal', 'active', NULL, 'medical', 'Asistencia médica requerida', 'high', 1770476247),
('inc_1770476248523', NULL, 'Incidente simulado desde Debug Panel', NULL, NULL, 'Tribuna Principal', 'active', NULL, 'fire', 'Alerta de fuego en Zona D', 'high', 1770476248),
('inc_1770476248941', NULL, 'Incidente simulado desde Debug Panel', NULL, NULL, 'Tribuna Principal', 'active', NULL, 'crowd', 'Aglomeración excesiva en T1', 'high', 1770476248);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `news`
--

CREATE TABLE `news` (
  `id` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `title` text COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `content` text COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `timestamp` int(11) DEFAULT NULL,
  `category` text COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `priority` text COLLATE utf8mb4_unicode_ci DEFAULT NULL
) ENGINE=MyISAM DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `news`
--

INSERT INTO `news` (`id`, `title`, `content`, `timestamp`, `category`, `priority`) VALUES
('a7c3fdb1-922f-452b-88b6-32004311d555', 'SEX', 'SEX', 1770473329, 'DRIVER_NEWS', 'HIGH'),
('57192532-aeab-47f3-9645-0b9edc8e8c27', 'awdas', 'dwasdawsdwasdwa', 1770473340, 'GENERAL', 'LOW'),
('alert_1770476244419', '🛡️ Zona restringida Pit Lane', 'Alerta de prueba generada por Debug Panel', 1770476244, 'SAFETY', 'HIGH'),
('alert_1770476245153', '⚠️ Previsión de lluvia a las 16:00', 'Alerta de prueba generada por Debug Panel', 1770476245, 'WEATHER', 'MEDIUM'),
('alert_1770476245562', '🚗 Retención en acceso norte', 'Alerta de prueba generada por Debug Panel', 1770476245, 'TRAFFIC', 'MEDIUM'),
('alert_1770476246046', '📅 Carrera retrasada 30 min', 'Alerta de prueba generada por Debug Panel', 1770476246, 'SCHEDULE_CHANGE', 'MEDIUM');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `orders`
--

CREATE TABLE `orders` (
  `id` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `order_id` text COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `user_uid` text COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `status` text COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `items_json` text COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `total_amount` double DEFAULT NULL,
  `platform` text COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `payment_token` text COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` text COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `updated_at` text COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `user_id` text COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `items` text COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `total` double DEFAULT NULL,
  `stand_name` text COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `stand_id` text COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `pickup_code` text COLLATE utf8mb4_unicode_ci DEFAULT NULL
) ENGINE=MyISAM DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `orders`
--

INSERT INTO `orders` (`id`, `order_id`, `user_uid`, `status`, `items_json`, `total_amount`, `platform`, `payment_token`, `created_at`, `updated_at`, `user_id`, `items`, `total`, `stand_name`, `stand_id`, `pickup_code`) VALUES
('e9b60aa2-1aa0-4d1f-8456-63123160f062', '8e0cf3a8-fb64-4e0f-9380-c4b3a81a83b0', '0djGLQYjKvNNjWoS7BGBU1WlB1B2', 'DELIVERED', '[{\"product_id\":\"72476f37-0095-49ec-9ff1-1a73352147b6\",\"quantity\":1,\"unit_price\":6.5},{\"product_id\":\"206d5130-7550-41b5-ab7a-548a64670b4d\",\"quantity\":1,\"unit_price\":5.0},{\"product_id\":\"8afd6ed2-b984-4057-a26e-200488f12b6f\",\"quantity\":1,\"unit_price\":5.5},{\"product_id\":\"940c328e-e280-46ba-aba8-3f065fa2066b\",\"quantity\":1,\"unit_price\":2.5},{\"product_id\":\"5cb7afd2-d774-408e-a7c7-19ca7fc2ce99\",\"quantity\":1,\"unit_price\":7.0},{\"product_id\":\"7c5b4f61-3f43-4993-a002-c89167d49a2f\",\"quantity\":1,\"unit_price\":3.5},{\"product_id\":\"dbc401ec-7b84-4d10-ac85-903d1fece04a\",\"quantity\":8,\"unit_price\":35.0},{\"product_id\":\"4f588643-e246-4944-98bc-aefcd3e8ecbc\",\"quantity\":17,\"unit_price\":45.0}]', 1075, 'ANDROID', 'SIMULATED_TOKEN', '2025-12-15 13:35:09', '2025-12-15 12:38:14', NULL, NULL, NULL, NULL, NULL, NULL),
('b58377d8-974e-499d-94c6-40af10ce541a', '44c80695-1ed4-4896-aaed-bb67801e83bc', '0djGLQYjKvNNjWoS7BGBU1WlB1B2', 'DELIVERED', '[{\"product_id\":\"8\",\"quantity\":1,\"unit_price\":45.0}]', 45, 'ANDROID', 'SIMULATED_TOKEN', '2025-12-15 13:13:38', '2025-12-15 12:35:20', NULL, NULL, NULL, NULL, NULL, NULL),
('13e7c76f-fb74-4d00-a410-b916ab4c6ab8', '552098a7-8237-4254-86e7-ac1b08a96f91', '0djGLQYjKvNNjWoS7BGBU1WlB1B2', 'DELIVERED', '[{\"product_id\":\"72476f37-0095-49ec-9ff1-1a73352147b6\",\"quantity\":1,\"unit_price\":6.5}]', 6.5, 'ANDROID', 'SIMULATED_TOKEN', '2025-12-15 13:43:21', '2025-12-15 12:54:13', NULL, NULL, NULL, NULL, NULL, NULL),
('6eb1d558-98d5-48aa-8d11-53bdbd3b9ff5', 'd17c952d-d7a3-4a37-bf7d-b47beb309e27', '0djGLQYjKvNNjWoS7BGBU1WlB1B2', 'DELIVERED', '[{\"product_id\":\"72476f37-0095-49ec-9ff1-1a73352147b6\",\"quantity\":1,\"unit_price\":6.5},{\"product_id\":\"206d5130-7550-41b5-ab7a-548a64670b4d\",\"quantity\":1,\"unit_price\":5.0},{\"product_id\":\"8afd6ed2-b984-4057-a26e-200488f12b6f\",\"quantity\":1,\"unit_price\":5.5}]', 17, 'ANDROID', 'SIMULATED_TOKEN', '2025-12-15 13:53:58', '2025-12-15 13:02:05', NULL, NULL, NULL, NULL, NULL, NULL),
('0e9c8963-f2d0-4a46-a3eb-b13727f44ccf', 'cd30e292-5f0e-47a8-b5fe-ae0febc334e8', '0djGLQYjKvNNjWoS7BGBU1WlB1B2', 'DELIVERED', '[{\"product_id\":\"72476f37-0095-49ec-9ff1-1a73352147b6\",\"quantity\":1,\"unit_price\":6.5},{\"product_id\":\"206d5130-7550-41b5-ab7a-548a64670b4d\",\"quantity\":1,\"unit_price\":5.0},{\"product_id\":\"8afd6ed2-b984-4057-a26e-200488f12b6f\",\"quantity\":1,\"unit_price\":5.5},{\"product_id\":\"940c328e-e280-46ba-aba8-3f065fa2066b\",\"quantity\":1,\"unit_price\":2.5},{\"product_id\":\"5cb7afd2-d774-408e-a7c7-19ca7fc2ce99\",\"quantity\":1,\"unit_price\":7.0}]', 26.5, 'ANDROID', 'SIMULATED_TOKEN', '2025-12-15 14:03:27', '2025-12-15 13:04:00', NULL, NULL, NULL, NULL, NULL, NULL),
('f634953c-8003-47a2-a498-33b43020146e', 'f074e37f-6388-444f-88c8-086885b56a6e', '0djGLQYjKvNNjWoS7BGBU1WlB1B2', 'DELIVERED', '[{\"product_id\":\"206d5130-7550-41b5-ab7a-548a64670b4d\",\"quantity\":1,\"unit_price\":5.0}]', 5, 'ANDROID', 'SIMULATED_TOKEN', '2025-12-15 14:08:56', '2025-12-15 13:09:18', NULL, NULL, NULL, NULL, NULL, NULL),
('ba826127-6a7d-4463-8ce0-ffaf6c22dab4', 'f620e4ec-1435-44d6-94f2-c79039eaa843', '0djGLQYjKvNNjWoS7BGBU1WlB1B2', 'DELIVERED', '[{\"product_id\":\"72476f37-0095-49ec-9ff1-1a73352147b6\",\"quantity\":1,\"unit_price\":6.5},{\"product_id\":\"206d5130-7550-41b5-ab7a-548a64670b4d\",\"quantity\":1,\"unit_price\":5.0},{\"product_id\":\"8afd6ed2-b984-4057-a26e-200488f12b6f\",\"quantity\":1,\"unit_price\":5.5},{\"product_id\":\"940c328e-e280-46ba-aba8-3f065fa2066b\",\"quantity\":1,\"unit_price\":2.5}]', 19.5, 'ANDROID', 'SIMULATED_TOKEN', '2025-12-15 15:38:40', '2025-12-15 14:45:42', NULL, NULL, NULL, NULL, NULL, NULL),
('9f8037d0-338c-4825-a5cc-4aba0c60f440', '76c33164-25c2-4c83-8411-ccd40428190e', '0djGLQYjKvNNjWoS7BGBU1WlB1B2', 'DELIVERED', '[{\"product_id\":\"72476f37-0095-49ec-9ff1-1a73352147b6\",\"quantity\":2,\"unit_price\":6.5},{\"product_id\":\"206d5130-7550-41b5-ab7a-548a64670b4d\",\"quantity\":2,\"unit_price\":5.0},{\"product_id\":\"7c5b4f61-3f43-4993-a002-c89167d49a2f\",\"quantity\":5,\"unit_price\":3.5},{\"product_id\":\"5cb7afd2-d774-408e-a7c7-19ca7fc2ce99\",\"quantity\":3,\"unit_price\":7.0}]', 61.5, 'ANDROID', 'SIMULATED_TOKEN', '2025-12-15 22:59:10', '2025-12-18 15:13:04', NULL, NULL, NULL, NULL, NULL, NULL),
('66eded86-cbdb-4af3-93a4-879b5aaa989d', '6020590b-a9ef-4972-991b-9d478639c0e1', '0djGLQYjKvNNjWoS7BGBU1WlB1B2', 'DELIVERED', '[{\"product_id\":\"36c2a740-7163-4f51-b002-dec60b48ea11\",\"quantity\":4,\"unit_price\":5.0}]', 20, 'ANDROID', 'DEMO_TOKEN_aaa97552-2730-4d79-8135-a2bfcfd60569', '2026-02-07 14:14:39', '2026-02-07 13:16:24', NULL, NULL, NULL, NULL, NULL, NULL),
('fa39e92c-d8ff-4b14-92e1-253fe4a9dd60', 'da605a5e-9e70-4540-b83e-d0ed9e95c3dd', '0djGLQYjKvNNjWoS7BGBU1WlB1B2', 'DELIVERED', '[{\"product_id\":\"eca16f20-da11-4728-9f54-e897306b1ed6\",\"quantity\":1,\"unit_price\":55.0},{\"product_id\":\"e3583e4c-4781-4f2b-8e4f-794d15a74d62\",\"quantity\":1,\"unit_price\":33.0}]', 88, 'ANDROID', 'SIMULATED_TOKEN', '2025-12-18 16:13:47', '2025-12-18 15:14:05', NULL, NULL, NULL, NULL, NULL, NULL),
('8b47a95f-9a3b-45db-9fbe-4d1308137932', '4381fe93-b1f8-489c-8d82-f47301916162', '0djGLQYjKvNNjWoS7BGBU1WlB1B2', 'DELIVERED', '[{\"product_id\":\"206d5130-7550-41b5-ab7a-548a64670b4d\",\"quantity\":1,\"unit_price\":5.0},{\"product_id\":\"8afd6ed2-b984-4057-a26e-200488f12b6f\",\"quantity\":1,\"unit_price\":5.5},{\"product_id\":\"940c328e-e280-46ba-aba8-3f065fa2066b\",\"quantity\":1,\"unit_price\":2.5}]', 13, 'ANDROID', 'SIMULATED_TOKEN', '2025-12-20 22:04:23', '2026-02-02 16:24:12', NULL, NULL, NULL, NULL, NULL, NULL),
('03559ad0-a4dc-4fc4-a044-21ff200c7682', 'c0406567-dde9-4a93-a6eb-38da5a8a2f1b', '0djGLQYjKvNNjWoS7BGBU1WlB1B2', 'DELIVERED', '[{\"product_id\":\"eca16f20-da11-4728-9f54-e897306b1ed6\",\"quantity\":11,\"unit_price\":55.0},{\"product_id\":\"e3583e4c-4781-4f2b-8e4f-794d15a74d62\",\"quantity\":11,\"unit_price\":33.0}]', 968, 'ANDROID', 'DEMO_TOKEN_f422189f-0192-46c6-bf46-29f0cc19c085', '2026-02-02 17:23:27', '2026-02-02 16:24:30', NULL, NULL, NULL, NULL, NULL, NULL),
('cccb796f-1821-484c-864d-e474dbf6f4cb', '067ef81a-44b9-4590-b2ad-c57c989adb36', '0djGLQYjKvNNjWoS7BGBU1WlB1B2', 'PAID', '[{\"product_id\":\"72476f37-0095-49ec-9ff1-1a73352147b6\",\"quantity\":4,\"unit_price\":6.5}]', 26, 'ANDROID', 'DEMO_TOKEN_d352115a-c43d-4ae5-9cbf-878ab6b359d4', '2026-02-26 13:12:19', '2026-02-26 13:12:19', NULL, NULL, NULL, NULL, NULL, NULL);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `products`
--

CREATE TABLE `products` (
  `id` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `product_id` text COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `name` text COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `description` text COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `price` double DEFAULT NULL,
  `stock` int(11) DEFAULT NULL,
  `category` text COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `image_url` text COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `is_active` tinyint(1) DEFAULT NULL,
  `in_stock` int(11) DEFAULT NULL,
  `emoji` text COLLATE utf8mb4_unicode_ci DEFAULT NULL
) ENGINE=MyISAM DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `products`
--

INSERT INTO `products` (`id`, `product_id`, `name`, `description`, `price`, `stock`, `category`, `image_url`, `is_active`, `in_stock`, `emoji`) VALUES
('72476f37-0095-49ec-9ff1-1a73352147b6', '1', 'Bocadillo Jamón', 'Delicioso bocadillo de jamón serrano', 6.5, 100, 'Comida', '', 1, 1, '🥪'),
('206d5130-7550-41b5-ab7a-548a64670b4d', '2', 'Cerveza Estrella', 'Cerveza fría 33cl', 5, 100, 'Bebidas', '', 1, 1, '🍺'),
('8afd6ed2-b984-4057-a26e-200488f12b6f', '3', 'Hot Dog', 'Perrito caliente con salsas', 5.5, 100, 'Comida', '', 1, 1, '🌭'),
('940c328e-e280-46ba-aba8-3f065fa2066b', '4', 'Agua 500ml', 'Agua mineral natural', 2.5, 100, 'Bebidas', '', 1, 1, '💧'),
('5cb7afd2-d774-408e-a7c7-19ca7fc2ce99', '5', 'Nachos con Queso', 'Nachos crujientes con salsa de queso', 7, 100, 'Comida', '', 1, 1, '🧀'),
('7c5b4f61-3f43-4993-a002-c89167d49a2f', '6', 'Coca-Cola', 'Refresco de cola 33cl', 3.5, 100, 'Bebidas', '', 1, 1, '🍹'),
('e3583e4c-4781-4f2b-8e4f-794d15a74d62', NULL, 'Cangreburger', NULL, 33, NULL, 'Comida', NULL, NULL, 1, '🍔'),
('36c2a740-7163-4f51-b002-dec60b48ea11', NULL, 'Pizza', NULL, 5, NULL, 'Comida', NULL, NULL, 1, '🍕'),
('eca16f20-da11-4728-9f54-e897306b1ed6', NULL, 'pipas', NULL, 55, NULL, 'Comida', NULL, NULL, 1, '🍔'),
('37d6e918-07f7-4a63-9a7c-9b58dfa6e050', NULL, 'Kebab mixto', NULL, 10000, NULL, 'Comida', NULL, NULL, 1, '🍔');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `users`
--

CREATE TABLE `users` (
  `id` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `email` text COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `uid` text COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `last_login` double DEFAULT NULL,
  `display_name` text COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `photo_url` text COLLATE utf8mb4_unicode_ci DEFAULT NULL
) ENGINE=MyISAM DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `users`
--

INSERT INTO `users` (`id`, `email`, `uid`, `last_login`, `display_name`, `photo_url`) VALUES
('4ddbe6c9-9275-46d2-a122-4d91fafe11e7', 'asmx24dcolet@inslaferreria.cat', 'Lv6lzHGQKRYLcNzVN4hWs0mXE972', 1765899425705.2158, 'Daniel Fernando Colet Sanchez', 'https://lh3.googleusercontent.com/a/ACg8ocK8IEBouiwOV7Wkzl_wUiiiwV_Rg35k-sycRHAN2Tb38vit8SY=s96-c'),
('d2fb464a-aa1f-4752-834c-ffad0c1ce470', 'asmx24dcolet@inslaferreria.cat', 'Lv6lzHGQKRYLcNzVN4hWs0mXE972', 1765899901337.733, 'Daniel Fernando Colet Sanchez', 'https://lh3.googleusercontent.com/a/ACg8ocK8IEBouiwOV7Wkzl_wUiiiwV_Rg35k-sycRHAN2Tb38vit8SY=s96-c');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `user_collectibles`
--

CREATE TABLE `user_collectibles` (
  `id` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `collectible_id` text COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `unlocked` tinyint(1) DEFAULT NULL,
  `unlocked_at` int(11) DEFAULT NULL
) ENGINE=MyISAM DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `user_collectibles`
--

INSERT INTO `user_collectibles` (`id`, `collectible_id`, `unlocked`, `unlocked_at`) VALUES
('c01', 'c01', 0, 0),
('c02', 'c02', 0, 0),
('c03', 'c03', 0, 0),
('c04', 'c04', 0, 0),
('c05', 'c05', 0, 0),
('c06', 'c06', 0, 0),
('c07', 'c07', 0, 0),
('c08', 'c08', 0, 0),
('c09', 'c09', 0, 0),
('c10', 'c10', 0, 0),
('c11', 'c11', 0, 0),
('c12', 'c12', 0, 0),
('c13', 'c13', 0, 0),
('c14', 'c14', 0, 0),
('c15', 'c15', 0, 0),
('c16', 'c16', 0, 0),
('c17', 'c17', 0, 0),
('c18', 'c18', 0, 0),
('c19', 'c19', 0, 0),
('c20', 'c20', 0, 0),
('c21', 'c21', 0, 0),
('c22', 'c22', 0, 0),
('c23', 'c23', 0, 0),
('c24', 'c24', 0, 0);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `zone_traffic`
--

CREATE TABLE `zone_traffic` (
  `id` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `name` text COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `type` text COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `status` text COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `capacity` int(11) DEFAULT NULL,
  `currentOccupancy` int(11) DEFAULT NULL,
  `temperature` int(11) DEFAULT NULL,
  `waitTime` int(11) DEFAULT NULL,
  `entryRate` int(11) DEFAULT NULL,
  `exitRate` int(11) DEFAULT NULL,
  `current_occupancy` int(11) DEFAULT NULL,
  `wait_time` int(11) DEFAULT NULL,
  `entry_rate` int(11) DEFAULT NULL,
  `exit_rate` int(11) DEFAULT NULL,
  `updated_at` text COLLATE utf8mb4_unicode_ci DEFAULT NULL
) ENGINE=MyISAM DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `zone_traffic`
--

INSERT INTO `zone_traffic` (`id`, `name`, `type`, `status`, `capacity`, `currentOccupancy`, `temperature`, `waitTime`, `entryRate`, `exitRate`, `current_occupancy`, `wait_time`, `entry_rate`, `exit_rate`, `updated_at`) VALUES
('grada-t1-recta-principal', 'Grada T1 - Recta Principal', 'GRADA', 'SATURADA', 15000, 0, 24, 0, 0, 0, 0, 0, 0, 0, '2026-02-26T12:09:37.941Z'),
('grada-t2-curva-ascari', 'Grada T2 - Curva Ascari', 'GRADA', 'CERRADA', 12000, 0, 26, 0, 0, 0, 0, 0, 0, 0, '2026-02-26T12:09:45.027Z'),
('fan-zone-principal', 'Fan Zone Principal', 'FANZONE', 'CERRADA', 7600, 0, 25, 0, 0, 0, 0, 0, 0, 0, '2026-02-26T12:09:47.255Z'),
('paddock-vip-boxes', 'Paddock VIP - Boxes', 'PADDOCK', 'CERRADA', 3500, 0, 22, 0, 0, 0, 0, 0, 0, 0, '2026-02-26T12:09:47.888Z'),
('vial-acceso-a-norte', 'Vial Acceso A - Norte', 'VIAL', 'CERRADA', 5000, 0, 23, 0, 0, 0, 0, 0, 0, 0, '2026-02-26T12:09:44.335Z'),
('grada-t3-chicane', 'Grada T3 - Chicane', 'GRADA', 'CERRADA', 18000, 0, 24, 0, 0, 0, 0, 0, 0, 0, '2026-02-26T12:09:45.830Z'),
('fan-zone-tecnologica', 'Fan Zone Tecnológica', 'FANZONE', 'CERRADA', 4500, 0, 25, 0, 0, 0, 0, 0, 0, 0, '2026-02-26T12:09:46.612Z');

--
-- Índices para tablas volcadas
--

--
-- Indices de la tabla `beacons`
--
ALTER TABLE `beacons`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `idx_beacon_uid` (`beacon_uid`);

--
-- Indices de la tabla `beacon_logs`
--
ALTER TABLE `beacon_logs`
  ADD PRIMARY KEY (`id`);

--
-- Indices de la tabla `circuit_state`
--
ALTER TABLE `circuit_state`
  ADD PRIMARY KEY (`id`);

--
-- Indices de la tabla `commands`
--
ALTER TABLE `commands`
  ADD PRIMARY KEY (`id`);

--
-- Indices de la tabla `food_stands`
--
ALTER TABLE `food_stands`
  ADD PRIMARY KEY (`id`);

--
-- Indices de la tabla `gamification_profile`
--
ALTER TABLE `gamification_profile`
  ADD PRIMARY KEY (`id`);

--
-- Indices de la tabla `groups`
--
ALTER TABLE `groups`
  ADD PRIMARY KEY (`id`);

--
-- Indices de la tabla `incidents`
--
ALTER TABLE `incidents`
  ADD PRIMARY KEY (`id`);

--
-- Indices de la tabla `news`
--
ALTER TABLE `news`
  ADD PRIMARY KEY (`id`);

--
-- Indices de la tabla `orders`
--
ALTER TABLE `orders`
  ADD PRIMARY KEY (`id`);

--
-- Indices de la tabla `products`
--
ALTER TABLE `products`
  ADD PRIMARY KEY (`id`);

--
-- Indices de la tabla `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`id`);

--
-- Indices de la tabla `user_collectibles`
--
ALTER TABLE `user_collectibles`
  ADD PRIMARY KEY (`id`);

--
-- Indices de la tabla `zone_traffic`
--
ALTER TABLE `zone_traffic`
  ADD PRIMARY KEY (`id`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
