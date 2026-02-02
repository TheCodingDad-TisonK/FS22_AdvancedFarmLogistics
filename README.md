# Advanced Farm Logistics Manager
![Downloads](https://img.shields.io/github/downloads/TheCodingDad-TisonK/FS22_AdvancedFarmLogistics/total?style=for-the-badge)
![Release](https://img.shields.io/github/v/release/TheCodingDad-TisonK/FS22_AdvancedFarmLogistics?style=for-the-badge)
![License](https://img.shields.io/badge/license-All%20Rights%20Reserved-red?style=for-the-badge)

A comprehensive farm management mod for Farming Simulator 22 that adds supply chain logistics, worker AI management, and equipment maintenance systems.

## Features

### 🚚 Supply Chain Management
- **Inventory Tracking**: Monitor stock levels of seeds, fertilizer, fuel, and pesticides
- **Automated Purchase Orders**: Smart ordering system with economic order quantity calculations
- **Supplier System**: Three supplier types with different reliability, prices, and delivery times
- **Delivery Scheduling**: Track deliveries from order to arrival
- **Inventory Optimization**: Automatic reordering based on demand forecasting

### 👨‍🌾 Worker AI Management
- **Hire/Fire System**: Recruit workers with varying skills and wages
- **Task Assignment**: Assign workers to planting, harvesting, transport, or maintenance tasks
- **Skill Progression**: Workers improve skills with experience
- **Performance Tracking**: Monitor worker efficiency and task completion
- **Wage Management**: Weekly wage calculations and budget planning

### 🔧 Equipment Maintenance
- **Preventive Maintenance**: Schedule regular maintenance to prevent breakdowns
- **Breakdown System**: Equipment can fail with increasing risk over time
- **Cost Tracking**: Monitor repair and maintenance expenses
- **Maintenance History**: View complete service records for all equipment
- **Risk Calculation**: Visual breakdown risk indicators

### 📊 Logistics Dashboard
- **System Overview**: Comprehensive status display of all logistics operations
- **Real-time Monitoring**: Track supply chains, deliveries, and worker activities
- **Financial Summary**: View total wages, maintenance costs, and inventory value
- **Event System**: Dynamic logistics events (disruptions, opportunities, strikes)

## Installation

1. Download the mod folder
2. Extract to your FS22 mods directory:
   - **Windows**: `C:\Users\[YourName]\Documents\My Games\FarmingSimulator2022\mods\`
   - **Mac**: `~/Library/Application Support/FarmingSimulator2022/mods/`
3. Enable the mod in-game via the Mods menu
4. Load your save game

## Controls

- **L Key**: Open Logistics Manager interface
- **Console Commands** (press ` to open console):
  - `afl status` - Show system status
  - `afl workers` - List all workers
  - `afl supply` - Show supply chains
  - `afl maintenance` - Show maintenance schedule
  - `afl event` - Trigger a test event

## GUI Interface

### 1. Logistics Dashboard
- System status overview
- Supply chain efficiency
- Active deliveries
- Warehouse inventory
- Order management

### 2. Worker Manager
- Hired workers list
- Available workers pool
- Worker statistics
- Task assignment
- Hire/fire controls

### 3. Maintenance Schedule
- Equipment maintenance calendar
- Breakdown risk indicators
- Maintenance history
- Register new equipment
- Perform maintenance

## Gameplay Integration

### Starting Out
1. The mod automatically initializes with default inventory
2. Basic supply chains are established for seeds, fertilizer, and fuel
3. Three workers are available for hiring
4. Get in a vehicle and register it for maintenance tracking

### Daily Operations
1. Monitor inventory levels in the dashboard
2. Hire workers as needed for farm operations
3. Assign tasks to workers based on farm needs
4. Schedule regular equipment maintenance
5. Respond to logistics events as they occur

### Financial Management
- **Worker Wages**: Weekly costs based on 40-hour work week
- **Maintenance Costs**: Regular upkeep to prevent expensive breakdowns
- **Order Expenses**: Purchase costs + shipping fees
- **Breakdown Repairs**: Emergency repair costs for neglected equipment

## Configuration

Mod settings are automatically saved to:
`Documents/My Games/FarmingSimulator2022/mods/settings/AdvancedFarmLogistics.xml`

### Adjustable Settings:
- Logistics difficulty (1-5)
- Worker AI skill level
- Maintenance frequency (days)
- Supply chain complexity
- Notification preferences
- Auto-hire/auto-maintenance options

## Compatibility

- **Version**: Farming Simulator 22
- **Multiplayer**: Supported
- **Other Mods**: Should be compatible with most mods
- **Save Games**: Can be added/removed from existing saves

## Troubleshooting

### Common Issues:

1. **Mod not appearing in game:**
   - Ensure correct installation path
   - Check mod is enabled in Mods menu
   - Verify game version compatibility

2. **GUI not opening (L key not working):**
   - Check key bindings in game settings
   - Ensure no other mod is using the L key
   - Try restarting the game

3. **Workers not appearing:**
   - Check farm has sufficient funds for hiring
   - Verify worker system is enabled in settings

4. **Equipment not registering:**
   - Get in the vehicle before trying to register
   - Check vehicle is owned by your farm

### Console Error Messages:
- If you see Lua errors in console, try:
  1. Disable other mods to check for conflicts
  2. Reinstall the mod
  3. Check game.log for detailed error information

## Support

For bug reports, suggestions, or questions:
1. Check the troubleshooting section above
2. Visit the mod's release page
3. Provide detailed information about the issue
   - Game version
   - Other mods installed
   - Steps to reproduce
   - Error messages if any

## Future Plans

Potential features for future updates:
- Expanded worker specializations
- More complex supply chain networks
- Equipment upgrade system
- Farm expansion planning
- Seasonal logistics challenges
- Multi-farm corporation management

---

## ⚖️ License

All rights reserved. Unauthorized redistribution, copying, or claiming this mod as your own is **strictly prohibited**.  
Original author: **TisonK** 

**Enjoy managing your farm logistics!** 🌾🚜📊
