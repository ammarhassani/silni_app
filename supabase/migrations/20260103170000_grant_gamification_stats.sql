-- =====================================================
-- Ensure GRANT for gamification stats function
-- =====================================================

GRANT EXECUTE ON FUNCTION get_admin_gamification_stats() TO authenticated;
GRANT EXECUTE ON FUNCTION get_admin_dashboard_overview() TO authenticated;
GRANT EXECUTE ON FUNCTION get_admin_user_growth(INT) TO authenticated;
GRANT EXECUTE ON FUNCTION get_admin_subscription_distribution() TO authenticated;
GRANT EXECUTE ON FUNCTION get_admin_interaction_stats() TO authenticated;
GRANT EXECUTE ON FUNCTION get_admin_top_users(INT) TO authenticated;
