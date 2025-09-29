'use client';

import { useState } from 'react';

interface Tab {
    id: string;
    title: string;
    content: React.ReactNode;
}

interface TabsProps {
    tabs: Tab[];
    defaultTab?: string;
}

export function Tabs({ tabs, defaultTab }: TabsProps) {
    const [activeTab, setActiveTab] = useState(defaultTab || tabs[0]?.id);

    const activeTabContent = tabs.find(tab => tab.id === activeTab)?.content;

    return (
        <div className="w-full">
            {/* Tab Headers */}
            <div className="flex border-b border-gray-700 mb-6">
                {tabs.map((tab) => (
                    <button
                        key={tab.id}
                        onClick={() => setActiveTab(tab.id)}
                        className={`flex-1 py-3 px-4 text-center font-medium transition-colors duration-200 ${activeTab === tab.id
                                ? 'text-white border-b-2 border-blue-500 bg-gray-800'
                                : 'text-gray-400 hover:text-gray-200 hover:bg-gray-800'
                            }`}
                    >
                        {tab.title}
                    </button>
                ))}
            </div>

            {/* Tab Content */}
            <div className="min-h-[200px]">
                {activeTabContent}
            </div>
        </div>
    );
} 